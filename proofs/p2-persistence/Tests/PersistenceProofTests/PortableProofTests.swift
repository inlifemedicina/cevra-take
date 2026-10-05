import XCTest
import Foundation
@testable import PersistenceProof

final class PortableProofTests: XCTestCase {
    private var temp: URL!
    override func setUpWithError() throws {
        temp = URL(fileURLWithPath: "/private/tmp/cevra-portable-proof-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: temp) }
    private func path(_ name: String) -> URL { temp.appendingPathComponent(name) }
    private func seed() throws -> Store {
        let store = Store(path("source"))
        try store.commit(Fixture.r1, payloads: ["O": Fixture.original])
        try store.commit(Fixture.r2, payloads: ["O": Fixture.original])
        return store
    }
    private func cli(_ args: [String]) throws -> (Int32, Data, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: try XCTUnwrap(ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"]))
        p.arguments = args
        var env = ProcessInfo.processInfo.environment; env.removeValue(forKey: "P2_FAULT"); p.environment = env
        let out = Pipe(), err = Pipe(); p.standardOutput = out; p.standardError = err
        try p.run()
        let output = out.fileHandleForReading.readDataToEndOfFile(), errors = err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, output, String(decoding: errors, as: UTF8.self))
    }
    func testCLIGroupedPortableRoundtripWithoutSource() throws {
        let source = try seed(), archive = path("project.tar"), restored = path("restored")
        let export = try cli(["export-file", source.root.path, archive.path])
        XCTAssertEqual(export.0, 0, export.2)
        guard export.0 == 0 else { return }
        let before = try Data(contentsOf: archive)
        try FileManager.default.removeItem(at: source.root) // Own synthetic fixture only.
        let restore = try cli(["restore-file", restored.path, archive.path])
        XCTAssertEqual(restore.0, 0, restore.2)
        guard restore.0 == 0 else { return }
        let reopen = try cli(["diagnose-readonly", restored.path])
        XCTAssertEqual(reopen.0, 0, reopen.2)
        XCTAssertEqual(reopen.1, try canonical(Fixture.r2))
        XCTAssertEqual(try Store(restored).load().1["O"], Fixture.original)
        XCTAssertEqual(try Data(contentsOf: archive), before)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: temp.path).sorted(), ["project.tar", "restored"])
        // Independent native archive reader lists exactly the standard members;
        // extraction is performed only by our bounded adapter.
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        p.arguments = ["-tf", archive.path]
        let out = Pipe(); p.standardOutput = out; try p.run()
        let names = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        p.waitUntilExit(); XCTAssertEqual(p.terminationStatus, 0)
        XCTAssertEqual(names, "metadata.json\nmanifest.json\noriginals/O.bin\n")
    }
    func testStreamingOriginalExceedingInlineBudget() throws {
        let original = path("synthetic.bin"), root = path("large"), archive = path("large.tar"), restored = path("restored")
        FileManager.default.createFile(atPath: original.path, contents: nil)
        let writer = try FileHandle(forWritingTo: original)
        let chunk = Data(repeating: 11, count: Store.STREAM_CHUNK_BYTES)
        for _ in 0..<(Store.MAX_INLINE_BYTES / chunk.count + 1) { try writer.write(contentsOf: chunk) }
        try writer.close()
        var snapshot = Fixture.r2
        snapshot.originals = [try Store.describeOriginal(id: "O", source: original)]
        try Store(root).commitFiles(snapshot, sources: ["O": original])
        try PortableProof.export(Store(root), to: archive)
        try PortableProof.restore(from: archive, to: restored)
        let (result, files) = try Store(restored).loadFiles()
        XCTAssertEqual(try canonical(result), try canonical(snapshot))
        XCTAssertEqual(try Store.describeOriginal(id: "O", source: XCTUnwrap(files["O"])), snapshot.originals[0])
        XCTAssertGreaterThan(snapshot.originals[0].byteCount, Store.MAX_INLINE_BYTES)
    }
    private func entries(_ archive: Data) -> [(String, Range<Int>, Range<Int>)] {
        var offset = 0, result: [(String, Range<Int>, Range<Int>)] = []
        while offset + 512 <= archive.count, archive[offset..<(offset + 512)].contains(where: { $0 != 0 }) {
            let name = String(decoding: archive[offset..<(offset + 100)].prefix(while: { $0 != 0 }), as: UTF8.self)
            let count = Int(String(decoding: archive[(offset + 124)..<(offset + 136)].prefix(while: { $0 != 0 }), as: UTF8.self), radix: 8)!
            result.append((name, offset..<(offset + 512), (offset + 512)..<(offset + 512 + count)))
            offset += 512 + count + (512 - count % 512) % 512
        }
        return result
    }
    private func rechecksum(_ bytes: inout Data, at offset: Int) {
        bytes.replaceSubrange((offset + 148)..<(offset + 156), with: Data(repeating: 32, count: 8))
        let sum = bytes[offset..<(offset + 512)].reduce(0) { $0 + Int($1) }
        let s = String(sum, radix: 8)
        bytes.replaceSubrange((offset + 148)..<(offset + 156), with: Data((String(repeating: "0", count: 6 - s.count) + s).utf8) + [0, 32])
    }
    func testCorruptionUnsafeEntriesAndTruncationNeverPublish() throws {
        let source = try seed(), archive = path("valid.tar")
        try PortableProof.export(source, to: archive)
        let valid = try Data(contentsOf: archive), members = entries(valid)
        let original = try XCTUnwrap(members.first(where: { $0.0 == "originals/O.bin" }))
        let manifest = try XCTUnwrap(members.first(where: { $0.0 == "manifest.json" }))
        let sourceBefore = try canonical(source.diagnoseReadOnly())
        for kind in ["payload", "checksum", "truncated", "duplicate", "traversal", "absolute", "symlink", "hardlink", "extension", "prefix", "extra", "size", "padding", "trailing", "version", "missing"] {
            var bytes = valid
            switch kind {
            case "payload": bytes[original.2.lowerBound] ^= 1
            case "checksum": bytes[100] ^= 1
            case "truncated": bytes.removeLast(1)
            case "duplicate":
                bytes.insert(contentsOf: valid[original.1.lowerBound..<(original.2.upperBound + (512 - original.2.count % 512) % 512)], at: bytes.count - 1024)
            case "traversal", "absolute", "extra":
                let name = kind == "traversal" ? "../escape.bin" : kind == "absolute" ? "/escape.bin" : "unexpected.bin"
                bytes.replaceSubrange(original.1, with: PortableProof.header(name, size: original.2.count))
            case "symlink", "hardlink", "extension":
                bytes[original.1.lowerBound + 156] = kind == "symlink" ? 50 : kind == "hardlink" ? 49 : 120
                rechecksum(&bytes, at: original.1.lowerBound)
            case "prefix": bytes[original.1.lowerBound + 345] = 65; rechecksum(&bytes, at: original.1.lowerBound)
            case "size": bytes.replaceSubrange(original.1, with: PortableProof.header(original.0, size: PortableProof.maximumArchiveBytes))
            case "padding":
                let metadata = members[0]; XCTAssertLessThan(metadata.2.upperBound, members[1].1.lowerBound)
                bytes[metadata.2.upperBound] = 1
            case "trailing": bytes[bytes.count - 1] = 1
            case "version":
                var json = String(decoding: bytes[manifest.2], as: UTF8.self)
                json = json.replacingOccurrences(of: "\"formatVersion\":1", with: "\"formatVersion\":9")
                XCTAssertEqual(Data(json.utf8).count, manifest.2.count)
                bytes.replaceSubrange(manifest.2, with: Data(json.utf8))
            case "missing": bytes.removeSubrange(original.1.lowerBound..<(original.2.upperBound + (512 - original.2.count % 512) % 512))
            default: XCTFail("Unknown fixture")
            }
            let input = path(kind + ".tar"), dest = path(kind + "-destination")
            try bytes.write(to: input)
            XCTAssertThrowsError(try PortableProof.restore(from: input, to: dest), kind)
            XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path), kind)
            XCTAssertEqual(try Data(contentsOf: input), bytes, kind)
            XCTAssertEqual(try canonical(source.diagnoseReadOnly()), sourceBefore, kind)
            XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: temp.path).contains(where: { $0.hasPrefix(".portable-proof-") }))
        }
    }
    func testExistingDestinationSymlinkInputAndInterruptedExport() throws {
        let source = try seed(), archive = path("valid.tar")
        try PortableProof.export(source, to: archive)
        let before = try Data(contentsOf: archive)
        XCTAssertThrowsError(try PortableProof.export(source, to: archive)) { XCTAssertEqual($0 as? ProofError, .destinationExists) }
        let existing = path("existing")
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: false)
        try Data([1, 2, 3]).write(to: existing.appendingPathComponent("keep"))
        XCTAssertThrowsError(try PortableProof.restore(from: archive, to: existing)) { XCTAssertEqual($0 as? ProofError, .destinationExists) }
        XCTAssertEqual(try Data(contentsOf: existing.appendingPathComponent("keep")), Data([1, 2, 3]))
        let link = path("link.tar")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: archive)
        XCTAssertThrowsError(try PortableProof.restore(from: link, to: path("link-destination")))
        XCTAssertFalse(FileManager.default.fileExists(atPath: path("link-destination").path))
        for kind in [FaultKind.noSpace, .denied] {
            for point in [Checkpoint.exportPayloadWritten, .beforeExportPublish] {
                let dest = path(kind.rawValue + point.rawValue + ".tar")
                XCTAssertThrowsError(try PortableProof.export(source, to: dest, fault: Fault(point: point, kind: kind)))
                XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
                XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: temp.path).contains(where: { $0.hasPrefix(".portable-proof-") }))
            }
        }
        XCTAssertEqual(try Data(contentsOf: archive), before)
        XCTAssertEqual(try canonical(source.diagnoseReadOnly()), try canonical(Fixture.r2))
    }
    func testControlJSONDuplicateKeysAreRejectedAndLongRevisionAccepted() throws {
        let source = Store(path("source")), archive = path("long.tar"), restored = path("long-restored")
        try source.commit(Fixture.r1, payloads: ["O": Fixture.original])
        var snapshot = Fixture.r2
        snapshot.revisions[1] = Revision(id: "R2", scriptID: "S", text: String(repeating: "Revisão PT / EN text\n", count: 5000))
        try source.commit(snapshot, payloads: ["O": Fixture.original])
        try PortableProof.export(source, to: archive)
        try PortableProof.restore(from: archive, to: restored)
        XCTAssertEqual(try canonical(Store(restored).diagnoseReadOnly()), try canonical(snapshot))
        let valid = try Data(contentsOf: archive)
        var malformed = Data()
        for (name, _, payload) in entries(valid) {
            var bytes = Data(valid[payload])
            if name == "manifest.json" {
                bytes = Data("{\"formatVersion\":1,".utf8) + bytes.dropFirst()
            }
            malformed.append(PortableProof.header(name, size: bytes.count)); malformed.append(bytes)
            malformed.append(Data(repeating: 0, count: (512 - bytes.count % 512) % 512))
        }
        malformed.append(Data(repeating: 0, count: 1024))
        let bad = path("duplicate-control.tar"), absent = path("duplicate-control-destination")
        try malformed.write(to: bad)
        XCTAssertThrowsError(try PortableProof.restore(from: bad, to: absent))
        XCTAssertFalse(FileManager.default.fileExists(atPath: absent.path))
        XCTAssertEqual(try Data(contentsOf: bad), malformed)
    }
}
