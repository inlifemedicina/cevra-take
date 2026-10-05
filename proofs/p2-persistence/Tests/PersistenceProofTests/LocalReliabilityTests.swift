import XCTest
import Foundation
import ManualTextProof
@testable import PersistenceProof

// Own disposable synthetic data only. No capture controller or historical sandbox.
final class LocalReliabilityTests: XCTestCase {
    private var temp: URL!
    override func setUpWithError() throws {
        temp = URL(fileURLWithPath: "/private/tmp/cevra-local-reliability-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: temp) }
    private func path(_ name: String) -> URL { temp.appendingPathComponent(name) }
    private func snapshot(_ text: String) -> Snapshot {
        var s = Fixture.r1
        s.revisions = [Revision(id: "R1", scriptID: "S", text: text)]
        return s
    }
    private func cli(_ command: String, _ root: URL, _ extra: URL? = nil) throws -> (Int32, Data, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: try XCTUnwrap(ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"]))
        process.arguments = [command, root.path] + (extra.map { [$0.path] } ?? [])
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "P2_FAULT")
        process.environment = env
        let output = Pipe(), error = Pipe()
        process.standardOutput = output; process.standardError = error
        try process.run()
        let bytes = output.fileHandleForReading.readDataToEndOfFile()
        let errors = error.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, bytes, String(decoding: errors, as: UTF8.self))
    }
    private func assertCLI(_ command: String, _ root: URL, equals s: Snapshot, file: StaticString = #filePath, line: UInt = #line) throws {
        let result = try cli(command, root)
        XCTAssertEqual(result.0, 0, result.2, file: file, line: line)
        XCTAssertEqual(result.1, try canonical(s), file: file, line: line)
    }
    private func fileHashes(_ root: URL) throws -> [String: String] {
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]))
        var result = [String: String]()
        for case let file as URL in enumerator {
            if try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true {
                let relative = String(file.path.dropFirst(root.path.count + 1))
                result[relative] = try Store.describeOriginal(id: "O", source: file).sha256
            }
        }
        return result
    }
    func testCanonicalEquivalentRewriteRejectedInline() throws {
        let a = snapshot("café"), b = snapshot("cafe\u{301}")
        XCTAssertEqual(a, b) // Swift text equality alone cannot protect the bytes.
        XCTAssertNotEqual(try canonical(a), try canonical(b))
        let root = path("inline")
        try Store(root).commit(a, payloads: ["O": Fixture.original])
        let before = try fileHashes(root)
        XCTAssertThrowsError(try Store(root).commit(b, payloads: ["O": Fixture.original])) {
            XCTAssertEqual($0 as? PersistenceProof.ProofError, .immutableHistory)
        }
        XCTAssertEqual(try fileHashes(root), before)
        XCTAssertEqual(try canonical(Store(root).loadFiles().0), try canonical(a))
    }
    func testCanonicalEquivalentRewriteRejectedWithNewRevisionFileAPI() throws {
        let a = snapshot("cafe\u{301}")
        var b = snapshot("café")
        b.revisions.append(Revision(id: "R2", scriptID: "S", text: "New revision / revisão posterior"))
        let source = path("synthetic.bin"), root = path("file")
        try Fixture.original.write(to: source)
        try Store(root).commitFiles(a, sources: ["O": source])
        let before = try fileHashes(root)
        XCTAssertThrowsError(try Store(root).commitFiles(b, sources: ["O": source])) {
            XCTAssertEqual($0 as? PersistenceProof.ProofError, .immutableHistory)
        }
        XCTAssertEqual(try fileHashes(root), before)
        XCTAssertEqual(try canonical(Store(root).loadFiles().0), try canonical(a))
    }
    func testGroupedPTENReadingRevisionSeparateProcessExportRestore() throws {
        for language in [Language.ptBR, .enUS] {
            let revision = try Fixtures.make(language: language, long: true)
            var reading = ReadingState(revision: revision)
            try reading.apply(reading.command(.resume))
            try reading.apply(reading.command(.select(revision.blocks[1].start)))
            try reading.apply(reading.command(.pause))
            let checkpoint = reading.checkpoint
            let resumed = try ReadingState(revision: revision, checkpoint: checkpoint)
            XCTAssertEqual(resumed.position, reading.position)
            XCTAssertEqual(resumed.phase, .paused)
            XCTAssertEqual(Data(revision.blocks.map(\.text).joined().utf8), Data(revision.text.utf8))
            let root = path(language.rawValue), bundle = path(language.rawValue + "-export"), restored = path(language.rawValue + "-restored")
            let r1 = snapshot(revision.text)
            try Store(root).commit(r1, payloads: ["O": Fixture.original])
            try assertCLI("verify", root, equals: r1)
            var r2 = r1
            r2.revisions.append(Revision(id: "R2", scriptID: "S", text: revision.text + "\nR2"))
            let files = try Store(root).loadFiles().1
            try Store(root).commitFiles(r2, sources: files)
            let originalHistory = try fileHashes(root)
            try Store(root).commitFiles(r2, sources: files)
            XCTAssertEqual(try fileHashes(root), originalHistory)
            XCTAssertEqual(try Store(root).loadFiles().0.takes.first?.revisionID, "R1")
            try Store(root).export(to: bundle)
            let status = try cli("restore", restored, bundle)
            XCTAssertEqual(status.0, 0, status.2)
            try assertCLI("verify", restored, equals: r2)
            XCTAssertEqual(try canonical(Store(restored).loadFiles().0), try canonical(r2))
            XCTAssertEqual(try Store(restored).load().1, ["O": Fixture.original])
            XCTAssertEqual(try fileHashes(root), originalHistory)
        }
    }
    func testVerifyStreamsLargeSyntheticOriginalAndReadOnlyCreatesNothing() throws {
        let source = path("source.bin"), root = path("large")
        FileManager.default.createFile(atPath: source.path, contents: nil)
        let writer = try FileHandle(forWritingTo: source)
        let chunk = Data(repeating: 7, count: Store.STREAM_CHUNK_BYTES)
        for _ in 0..<(Store.MAX_INLINE_BYTES / Store.STREAM_CHUNK_BYTES + 1) { try writer.write(contentsOf: chunk) }
        try writer.close()
        var s = snapshot("Synthetic PT/EN > inline budget")
        s.originals = [try Store.describeOriginal(id: "O", source: source)]
        try Store(root).commitFiles(s, sources: ["O": source])
        XCTAssertThrowsError(try Store(root).load()) { XCTAssertEqual($0 as? PersistenceProof.ProofError, .inlineTooLarge) }
        try assertCLI("verify", root, equals: s)
        try FileManager.default.removeItem(at: root.appendingPathComponent(".lock"))
        let before = try fileHashes(root)
        try assertCLI("diagnose-readonly", root, equals: s)
        XCTAssertEqual(try fileHashes(root), before)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".lock").path))
    }
    func testReadOnlyMissingRootDoesNotCreateStore() throws {
        let absent = path("absent")
        let result = try cli("diagnose-readonly", absent)
        XCTAssertNotEqual(result.0, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: absent.path))
    }
    func testRestoreRejectsExistingTamperedAndIncompatibleWithoutWritingDestination() throws {
        let root = path("valid")
        try Store(root).commit(Fixture.r1, payloads: ["O": Fixture.original])
        let sourceBefore = try fileHashes(root)
        for kind in ["existing", "tampered", "incompatible", "unexpected"] {
            let bundle = path(kind + "-bundle"), destination = path(kind + "-destination")
            try Store(root).export(to: bundle)
            if kind == "existing" {
                try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
            } else if kind == "tampered" {
                var payload = Fixture.original; payload[0] ^= 1
                try payload.write(to: bundle.appendingPathComponent("originals/O.bin"))
            } else if kind == "incompatible" {
                let file = bundle.appendingPathComponent("manifest.json")
                var manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
                manifest["formatVersion"] = 999
                try JSONSerialization.data(withJSONObject: manifest).write(to: file)
            } else { try Data([1]).write(to: bundle.appendingPathComponent("unexpected.bin")) }
            let bundleBefore = try fileHashes(bundle)
            XCTAssertThrowsError(try Store(root).restore(from: bundle, to: destination))
            XCTAssertEqual(try fileHashes(bundle), bundleBefore)
            XCTAssertEqual(try fileHashes(root), sourceBefore)
            if kind == "existing" { XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: destination.path).isEmpty) }
            else { XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path)) }
        }
    }
    func testInterruptedExportLeavesPublishedSourceAndNoFinalPackage() throws {
        let root = path("valid")
        try Store(root).commit(Fixture.r1, payloads: ["O": Fixture.original])
        let before = try fileHashes(root)
        for point in [Checkpoint.exportPayloadWritten, .beforeExportPublish] {
            let destination = path(point.rawValue)
            XCTAssertThrowsError(try Store(root).export(to: destination, fault: Fault(point: point, kind: .noSpace)))
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
            XCTAssertEqual(try fileHashes(root), before)
        }
    }
}
