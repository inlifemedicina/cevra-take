import XCTest
import Foundation
@testable import PersistenceProof

final class ProofTests: XCTestCase {
    private var temp: URL!
    override func setUpWithError() throws {
        temp=FileManager.default.temporaryDirectory.appendingPathComponent("cevra-p2-test-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:temp,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at:temp) }
    private func path(_ name: String) -> URL { temp.appendingPathComponent(name) }
    private struct Outcome { let status: Int32; let signal: Bool; let output: Data; let error: String }
    private func cli(_ command: String, _ root: URL, _ extra: URL? = nil, fault: String? = nil) throws -> Outcome {
        let p=Process()
        guard let executable=ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"] else { throw ProofError.noState }
        p.executableURL=URL(fileURLWithPath:executable)
        p.arguments=[command,root.path]+(extra.map { [$0.path] } ?? [])
        var environment=ProcessInfo.processInfo.environment
        environment.removeValue(forKey:"P2_FAULT")
        if let fault { environment["P2_FAULT"]=fault }
        p.environment=environment
        let out=Pipe(),err=Pipe()
        p.standardOutput=out;p.standardError=err
        try p.run()
        let data=out.fileHandleForReading.readDataToEndOfFile()
        let errors=err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return Outcome(status:p.terminationStatus,signal:p.terminationReason == .uncaughtSignal,output:data,error:String(decoding:errors,as:UTF8.self))
    }
    private func ok(_ o: Outcome, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(o.status,0,o.error,file:file,line:line)
    }
    private func seed(_ name: String = "project") throws -> URL {
        let root=path(name);ok(try cli("seed",root));return root
    }
    private func export(_ root: URL, _ name: String = "bundle") throws -> URL {
        let b=path(name);ok(try cli("export",root,b));return b
    }
    private func verify(_ root: URL, equals s: Snapshot) throws {
        let o=try cli("verify",root);ok(o);XCTAssertEqual(o.output,try canonical(s))
        let (_,bytes)=try Store(root).load()
        XCTAssertEqual(bytes,["O":Fixture.original])
    }
    private func rewriteJSON(_ file: URL, _ change: (inout [String:Any]) -> Void) throws {
        var object=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:file)) as? [String:Any])
        change(&object)
        try JSONSerialization.data(withJSONObject:object,options:.sortedKeys).write(to:file)
    }
    func testARealProcessRestartExactRecovery() throws {
        // Seed process exits normally. Verify runs in a distinct OS process.
        let root=try seed();try verify(root,equals:Fixture.r1)
        print("EVIDENCE A separate_process_restart=yes exact_recovery=yes")
    }
    func testBRevisionProvenanceAndIdempotentRetry() throws {
        let root=try seed();XCTAssertEqual(try Store(root).load().0.takes.first?.revisionID,"R1")
        ok(try cli("r2",root));try verify(root,equals:Fixture.r2)
        let gens=root.appendingPathComponent("generations")
        let before=try FileManager.default.contentsOfDirectory(atPath:gens.path)
        ok(try cli("r2",root))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:gens.path),before)
        XCTAssertEqual(try Store(root).load().0.takes.first?.revisionID,"R1")
        print("EVIDENCE B T_to_R1_before=yes after_R2=yes duplicates=0")
    }
    func testCOriginalSurvivesCacheDeletionAndHistoryRewriteRejected() throws {
        let root=try seed(),cache=root.appendingPathComponent("cache")
        try FileManager.default.createDirectory(at:cache,withIntermediateDirectories:false)
        try Data("discardable".utf8).write(to:cache.appendingPathComponent("derived.bin"))
        try FileManager.default.removeItem(at:cache)
        try verify(root,equals:Fixture.r1)
        var changed=Fixture.r1
        changed.revisions=[Revision(id:"R1",scriptID:"S",text:"attempted overwrite")]
        XCTAssertThrowsError(try Store(root).commit(changed,payloads:["O":Fixture.original])) { XCTAssertEqual($0 as? ProofError,.immutableHistory) }
        try verify(root,equals:Fixture.r1)
        print("EVIDENCE C original_byte_equality=yes original_hash="+SHA256.hex(Fixture.original))
    }
    func testDDeclaredExportManifestAndHashes() throws {
        let root=try seed();ok(try cli("r2",root));let b=try export(root)
        let json=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:b.appendingPathComponent("manifest.json"))) as? [String:Any])
        let hashes=try XCTUnwrap(json["hashes"] as? [String:String])
        XCTAssertEqual(Set(hashes.keys),["metadata.json","originals/O.bin"])
        for (name,hash) in hashes { XCTAssertEqual(SHA256.hex(try Data(contentsOf:b.appendingPathComponent(name))),hash) }
        XCTAssertEqual(hashes["metadata.json"],SHA256.hex(try canonical(Fixture.r2)))
        print("EVIDENCE D manifest_exact=yes metadata_R2_hash="+SHA256.hex(try canonical(Fixture.r2)))
    }
    func testERestoreInNewDestinationExactEquality() throws {
        let root=try seed();ok(try cli("r2",root));let b=try export(root),restored=path("restored")
        ok(try cli("restore",restored,b));try verify(restored,equals:Fixture.r2)
        XCTAssertEqual(try Store(root).load().0,try Store(restored).load().0)
        XCTAssertEqual(try Store(root).load().1,try Store(restored).load().1)
        print("EVIDENCE E export_restore_metadata_links_bytes_hashes_equal=yes")
    }
    func testFRestoreAndExportNeverOverwriteExistingDestination() throws {
        let root=try seed(),b=try export(root),existing=try seed("existing")
        let before=try cli("verify",existing).output
        let r=try cli("restore",existing,b)
        XCTAssertNotEqual(r.status,0);XCTAssertTrue(r.error.contains("destinationExists"))
        XCTAssertEqual(try cli("verify",existing).output,before)
        let empty=path("existing-empty");try FileManager.default.createDirectory(at:empty,withIntermediateDirectories:false)
        XCTAssertTrue(try cli("restore",empty,b).error.contains("destinationExists"))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath:empty.path).isEmpty)
        let manifest=try Data(contentsOf:b.appendingPathComponent("manifest.json"))
        XCTAssertTrue(try cli("export",root,b).error.contains("destinationExists"))
        XCTAssertEqual(try Data(contentsOf:b.appendingPathComponent("manifest.json")),manifest)
        print("EVIDENCE F overwrite=0 existing_empty_destination_rejected=yes")
    }
    func testGMissingOrTamperedOriginalExplicitFailure() throws {
        let root=try seed(),missing=try export(root,"missing"),tampered=try export(root,"tampered")
        try FileManager.default.removeItem(at:missing.appendingPathComponent("originals/O.bin"))
        let dst=path("missing-restored")
        let r=try cli("restore",dst,missing)
        XCTAssertNotEqual(r.status,0);XCTAssertTrue(r.error.contains("missingOriginal"));XCTAssertFalse(FileManager.default.fileExists(atPath:dst.path))
        try Data("tampered".utf8).write(to:tampered.appendingPathComponent("originals/O.bin"))
        XCTAssertTrue(try cli("restore",path("tampered-restored"),tampered).error.contains("corruptOriginal"))
        let h=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("CURRENT.json"))) as? [String:String])
        let original=root.appendingPathComponent("generations/"+h["generation"]!+"/originals/O.bin")
        try FileManager.default.removeItem(at:original)
        XCTAssertTrue(try cli("verify",root).error.contains("missingOriginal"))
        XCTAssertNotEqual(try cli("export",root,path("invalid-export")).status,0)
        XCTAssertFalse(FileManager.default.fileExists(atPath:path("invalid-export").path))
        print("EVIDENCE G missing_tampered_error=yes false_success=0")
    }
    func testHIncompatibleVersionDiagnosedWithoutOverwrite() throws {
        let root=try seed(),b=try export(root)
        let meta=b.appendingPathComponent("metadata.json")
        try rewriteJSON(meta) { $0["formatVersion"]=99 }
        let before=try Data(contentsOf:meta),destination=path("incompatible-restored")
        let r=try cli("restore",destination,b)
        XCTAssertTrue(r.error.contains("incompatibleVersion"));XCTAssertNotEqual(r.status,0)
        XCTAssertFalse(FileManager.default.fileExists(atPath:destination.path))
        XCTAssertEqual(try Data(contentsOf:meta),before)
        var incompatible=Fixture.r1;incompatible.formatVersion=99
        XCTAssertThrowsError(try Store(root).commit(incompatible,payloads:["O":Fixture.original])) { XCTAssertEqual($0 as? ProofError,.incompatibleVersion) }
        try verify(root,equals:Fixture.r1)
        print("EVIDENCE H incompatible_version_error=yes overwrite=0")
    }
    func testIInterruptedExportHasNoPublishedBundle() throws {
        let root=try seed()
        for point in [Checkpoint.exportPayloadWritten,.beforeExportPublish] {
            for kind in [FaultKind.death,.denied,.noSpace] {
                let b=path(point.rawValue+kind.rawValue)
                let r=try cli("export",root,b,fault:point.rawValue+":"+kind.rawValue)
                XCTAssertNotEqual(r.status,0)
                if kind == .death { XCTAssertTrue(r.signal);XCTAssertEqual(r.status,9) }
                else { XCTAssertTrue(r.error.contains("posix:"+(kind == .denied ? "13":"28"))) }
                XCTAssertFalse(FileManager.default.fileExists(atPath:b.path))
                try verify(root,equals:Fixture.r1)
                print("EVIDENCE I \(point.rawValue) \(kind.rawValue) final_bundle_absent=yes source_preserved=yes")
            }
        }
    }
    func testJFailureMatrixRecoveryAndRetry() throws {
        let points:[Checkpoint]=[.beforeOriginalWrite,.duringOriginalWrite,.beforeMetadataWrite,.duringMetadataWrite,.beforeGenerationPublish,.beforeHeadPublish,.afterHeadPublish]
        for point in points {
            for kind in [FaultKind.death,.denied,.noSpace] {
                let root=try seed(point.rawValue+kind.rawValue)
                let r=try cli("r2",root,fault:point.rawValue+":"+kind.rawValue)
                XCTAssertNotEqual(r.status,0)
                if kind == .death { XCTAssertTrue(r.signal);XCTAssertEqual(r.status,9) }
                else { XCTAssertTrue(r.error.contains("posix:"+(kind == .denied ? "13":"28"))) }
                let expected=point == .afterHeadPublish ? Fixture.r2 : Fixture.r1
                try verify(root,equals:expected)
                ok(try cli("r2",root));try verify(root,equals:Fixture.r2)
                let s=try Store(root).load().0
                XCTAssertEqual(s.revisions.count,2);XCTAssertEqual(s.takes.count,1);XCTAssertEqual(s.originals.count,1)
                print("EVIDENCE J \(point.rawValue) \(kind.rawValue) recovered=\(point == .afterHeadPublish ? "R2":"R1") original_preserved=yes retry_duplicates=0")
            }
        }
    }
    func testKAbsentOrFailingSyntheticAILeavesPersistenceIndependent() throws {
        enum FakeAIError: Error { case unavailable }
        let providers:[(() throws -> Void)?]=[nil,{throw FakeAIError.unavailable}]
        for (i,provider) in providers.enumerated() {
            // Test-only stub; there is no provider in the persistence implementation.
            if let provider { XCTAssertThrowsError(try provider()) }
            let root=try seed("ai-"+String(i));ok(try cli("r2",root))
            let b=try export(root,"ai-export-"+String(i)),dst=path("ai-restore-"+String(i))
            ok(try cli("restore",dst,b));try verify(dst,equals:Fixture.r2)
        }
        print("EVIDENCE K synthetic_AI_absent_failing=yes persistence_unchanged=yes real_AI=NOT_RUN")
    }
    func testSHA256KnownAnswerVectors() {
        XCTAssertEqual(SHA256.hex(Data()),"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(SHA256.hex(Data("abc".utf8)),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(SHA256.hex(Data(repeating:97,count:1_000_000)),"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
    func testRejectSymlinksUnsafeIDsAndDuplicateIDs() throws {
        var unsafe=Fixture.r1
        unsafe.originals=[Original(id:"../escape",sha256:SHA256.hex(Fixture.original),byteCount:Fixture.original.count)]
        XCTAssertThrowsError(try unsafe.validate())
        var dup=Fixture.r1;dup.takes.append(dup.takes[0]);XCTAssertThrowsError(try dup.validate())
        let root=try seed(),b=try export(root)
        try FileManager.default.removeItem(at:b.appendingPathComponent("originals/O.bin"))
        let outside=path("outside");try Fixture.original.write(to:outside)
        try FileManager.default.createSymbolicLink(at:b.appendingPathComponent("originals/O.bin"),withDestinationURL:outside)
        XCTAssertNotEqual(try cli("restore",path("symlink-restored"),b).status,0)
        XCTAssertEqual(try Data(contentsOf:outside),Fixture.original)
    }
}
