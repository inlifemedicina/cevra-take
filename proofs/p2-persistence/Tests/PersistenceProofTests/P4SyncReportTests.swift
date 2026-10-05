import XCTest
import Foundation
@testable import PersistenceProof

final class P4SyncReportTests: XCTestCase {
    private var temp: URL!
    override func setUpWithError() throws {
        temp = URL(fileURLWithPath: "/private/tmp/cevra-sync-report-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: temp) }
    private func path(_ name: String) -> URL { temp.appendingPathComponent(name) }
    private func config(_ version: Int = 1) -> P4SyncProtocol {
        P4SyncProtocol(formatVersion: version, protocolID: "SYNTHETIC-SYNC-001", maximumAbsoluteOffsetSeconds: 0.080, maximumDriftSeconds: 0.040)
    }
    private func annotations(offset: Double, uncertainty: Double, version: Int = 1) -> P4SyncAnnotations {
        P4SyncAnnotations(formatVersion: version, originalSHA256: SHA256.hex(Fixture.original), originalByteCount: Fixture.original.count,
            durationSeconds: 30, annotationMethod: "Synthetic numeric references only; no decoded media",
            observations: zip([P4SyncMark.start, .middle, .end], [1.0, 15.0, 29.0]).map {
                P4SyncObservation(mark: $0, videoSeconds: $1, audioSeconds: $1 + offset, uncertaintySeconds: uncertainty)
            })
    }
    private func write(_ config: P4SyncProtocol, _ annotations: P4SyncAnnotations) throws {
        try canonical(config).write(to: path("protocol.json")); try canonical(annotations).write(to: path("annotations.json"))
    }
    func testCLIReportsBoundedArithmeticWithExactInputHashesAndNoStoreWrites() throws {
        try write(config(), annotations(offset: 0.01, uncertainty: 0.002))
        let p = Process()
        p.executableURL = URL(fileURLWithPath: try XCTUnwrap(ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"]))
        p.arguments = ["sync-report", path("protocol.json").path, path("annotations.json").path]
        var env = ProcessInfo.processInfo.environment; env.removeValue(forKey: "P2_FAULT"); p.environment = env
        let out = Pipe(), err = Pipe(); p.standardOutput = out; p.standardError = err
        try p.run(); let bytes = out.fileHandleForReading.readDataToEndOfFile(), errors = err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit(); XCTAssertEqual(p.terminationStatus, 0, String(decoding: errors, as: UTF8.self))
        guard p.terminationStatus == 0 else { return }
        let report = try JSONDecoder().decode(P4SyncReport.self, from: bytes)
        XCTAssertEqual(report.arithmetic.status, .pass)
        XCTAssertEqual(report.physicalVerification, "NOT_ESTABLISHED_BY_THIS_COMMAND")
        XCTAssertEqual(report.evidenceKind, "CALLER_ANNOTATED_REFERENCES")
        XCTAssertEqual(report.protocolSHA256, SHA256.hex(try Data(contentsOf: path("protocol.json"))))
        XCTAssertEqual(report.annotationsSHA256, SHA256.hex(try Data(contentsOf: path("annotations.json"))))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: temp.path).sorted(), ["annotations.json", "protocol.json"])
    }
    func testAmbiguousAndFailedReferencesAreReportedWithoutPromotingPhysicalEvidence() throws {
        for (offset, uncertainty, expected) in [(0.01, 0.05, P4SyncStatus.notVerifiable), (0.2, 0.001, .fail)] {
            try write(config(), annotations(offset: offset, uncertainty: uncertainty))
            let report = try P4SyncReport.make(protocolFile: path("protocol.json"), annotationsFile: path("annotations.json"))
            XCTAssertEqual(report.arithmetic.status, expected)
            XCTAssertEqual(report.physicalVerification, "NOT_ESTABLISHED_BY_THIS_COMMAND")
        }
    }
    func testInvalidVersionMetadataOversizedAndSymlinkInputsAreRefusedReadOnly() throws {
        try write(config(9), annotations(offset: 0, uncertainty: 0))
        XCTAssertThrowsError(try P4SyncReport.make(protocolFile: path("protocol.json"), annotationsFile: path("annotations.json"))) { XCTAssertEqual($0 as? ProofError, .incompatibleVersion) }
        try write(config(), annotations(offset: 0, uncertainty: 0, version: 9))
        XCTAssertThrowsError(try P4SyncReport.make(protocolFile: path("protocol.json"), annotationsFile: path("annotations.json")))
        try write(config(), annotations(offset: 0, uncertainty: 0))
        var bad = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: path("annotations.json"))) as? [String: Any])
        bad["originalSHA256"] = "unverified"; try JSONSerialization.data(withJSONObject: bad).write(to: path("annotations.json"))
        XCTAssertThrowsError(try P4SyncReport.make(protocolFile: path("protocol.json"), annotationsFile: path("annotations.json"))) { XCTAssertEqual($0 as? ProofError, .invalidMetadata) }
        let bytes = Data(repeating: 32, count: Store.STREAM_CHUNK_BYTES + 1)
        try bytes.write(to: path("annotations.json"))
        XCTAssertThrowsError(try P4SyncReport.make(protocolFile: path("protocol.json"), annotationsFile: path("annotations.json"))) { XCTAssertEqual($0 as? ProofError, .inlineTooLarge) }
        XCTAssertEqual(try Data(contentsOf: path("annotations.json")), bytes)
        try FileManager.default.createSymbolicLink(at: path("link.json"), withDestinationURL: path("protocol.json"))
        XCTAssertThrowsError(try P4SyncReport.make(protocolFile: path("link.json"), annotationsFile: path("annotations.json")))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: temp.path).sorted(), ["annotations.json", "link.json", "protocol.json"])
    }
}
