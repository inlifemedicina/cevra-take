import XCTest
import Foundation
import Darwin
@testable import PersistenceProof

final class LargeOriginalTests: XCTestCase {
    private var temp: URL!
    override func setUpWithError() throws {
        temp=URL(fileURLWithPath:"/private/tmp/cevra-p2-large-test-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:temp,withIntermediateDirectories:false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at:temp) }
    private func path(_ n:String) -> URL { temp.appendingPathComponent(n) }
    private func head(_ root:URL) throws -> Data { try Data(contentsOf:root.appendingPathComponent("CURRENT.json")) }
    private func original(_ root:URL) throws -> URL { try XCTUnwrap(Store(root).loadFiles().1["O"]) }
    private func cli(_ command:String,_ root:URL,_ fault:String?=nil) throws -> Int32 {
        let p=Process();p.executableURL=URL(fileURLWithPath:try XCTUnwrap(ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"]))
        p.arguments=[command,root.path]
        var env=ProcessInfo.processInfo.environment;env.removeValue(forKey:"P2_FAULT")
        if let fault { env["P2_FAULT"]=fault };p.environment=env
        p.standardOutput=FileHandle.nullDevice;p.standardError=FileHandle.nullDevice
        try p.run();p.waitUntilExit();return p.terminationStatus
    }
    private func inline(_ data:Data) -> Snapshot {
        let s=Fixture.r1
        return Snapshot(formatVersion:1,projectID:s.projectID,revisions:s.revisions,takes:s.takes,
                        originals:[Original(id:"O",sha256:SHA256.hex(data),byteCount:data.count)])
    }
    func testInlineBoundarySymmetricAndRejectedBeforePublication() throws {
        for size in [Store.MAX_INLINE_BYTES-1,Store.MAX_INLINE_BYTES] {
            let b=Data(repeating:3,count:size),root=path("size-"+String(size)),s=inline(b)
            try Store(root).commit(s,payloads:["O":b])
            XCTAssertEqual(try Store(root).load().0,s)
            XCTAssertEqual(try Store(root).load().1["O"],b)
            let bundle=path("export-"+String(size)),restored=path("restored-"+String(size))
            try Store(root).export(to:bundle);try Store(root).restore(from:bundle,to:restored)
            XCTAssertEqual(try Store(restored).load().1["O"],b)
        }
        let root=path("unchanged")
        try Store(root).commit(Fixture.r1,payloads:["O":Fixture.original])
        let before=try head(root),large=Data(repeating:3,count:Store.MAX_INLINE_BYTES+1)
        XCTAssertThrowsError(try Store(root).commit(inline(large),payloads:["O":large])) { XCTAssertEqual($0 as? ProofError,.inlineTooLarge) }
        XCTAssertEqual(try head(root),before);XCTAssertEqual(try Store(root).load().1["O"],Fixture.original)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.appendingPathComponent("generations").path).count,1)
        let absent=path("no-store")
        XCTAssertThrowsError(try Store(absent).commit(inline(large),payloads:["O":large]))
        XCTAssertFalse(FileManager.default.fileExists(atPath:absent.path))
        print("EVIDENCE LARGE inline_boundary_minus1_exact_plus1=yes rejected_before_stage=yes")
    }
    func testInlineAggregateBudgetAndMetadataCap() throws {
        let data=Data(repeating:7,count:Store.MAX_INLINE_BYTES/2+1)
        var s=inline(data)
        s.originals.append(Original(id:"P",sha256:SHA256.hex(data),byteCount:data.count))
        XCTAssertThrowsError(try Store(path("aggregate")).commit(s,payloads:["O":data,"P":data])) { XCTAssertEqual($0 as? ProofError,.inlineTooLarge) }
        let f=path("source.bin");try data.write(to:f)
        let root=path("files")
        try Store(root).commitFiles(s,sources:["O":f,"P":f])
        XCTAssertEqual(try Store(root).loadFiles().0,s) // File reader has no aggregate media cap.
        XCTAssertThrowsError(try Store(root).load()) { XCTAssertEqual($0 as? ProofError,.inlineTooLarge) }
        let prior=try head(root)
        s.revisions.append(Revision(id:"R2",scriptID:"S",text:String(repeating:"a",count:Store.MAX_INLINE_BYTES)))
        XCTAssertThrowsError(try Store(root).commitFiles(s,sources:["O":f,"P":f])) { XCTAssertEqual($0 as? ProofError,.inlineTooLarge) }
        XCTAssertEqual(try head(root),prior)
    }
    func testStreamingRoundtripInNewProcessAndSelfContainedExport() throws {
        let base=path("large")
        XCTAssertEqual(try cli("large-seed",base),0)
        // A second CLI process must recover existing R1, edit R2, export, delete source and restore.
        XCTAssertEqual(try cli("large-roundtrip",base),0)
        XCTAssertEqual(try cli("large-verify",base.appendingPathComponent("restored")),0)
        XCTAssertFalse(FileManager.default.fileExists(atPath:base.appendingPathComponent("synthetic-source.bin").path))
        for name in ["project","restored"] {
            let r=base.appendingPathComponent(name)
            XCTAssertEqual(try Store(r).loadFiles().0,LargeFixture.snapshot(r2:true))
            XCTAssertEqual(try Store.describeOriginal(id:"O",source:original(r)),LargeFixture.snapshot().originals[0])
            XCTAssertThrowsError(try Store(r).load()) { XCTAssertEqual($0 as? ProofError,.inlineTooLarge) }
        }
        let manifest=try Data(contentsOf:base.appendingPathComponent("export/manifest.json"))
        let obj=try XCTUnwrap(JSONSerialization.jsonObject(with:manifest) as? [String:Any])
        XCTAssertEqual(obj["formatVersion"] as? Int,1)
        XCTAssertEqual(Set(try XCTUnwrap(obj["hashes"] as? [String:String]).keys),["metadata.json","originals/O.bin"])
        print("EVIDENCE LARGE file_ingest_new_process_export_restore=yes source_deleted=yes bytes=\(LargeFixture.byteCount) hash=\(LargeFixture.hash) T_to_R1=yes")
    }
    func testLargeCorruptionTruncationAndRestoreDoNotPublish() throws {
        let base=path("corrupt");try LargeFixture.seed(base)
        let project=base.appendingPathComponent("project"),bundle=path("bundle")
        try Store(project).export(to:bundle)
        let file=bundle.appendingPathComponent("originals/O.bin")
        let handle=try FileHandle(forWritingTo:file)
        try handle.seek(toOffset:12345);try handle.write(contentsOf:Data([0]));try handle.close()
        let dest=path("invalid-restored")
        XCTAssertThrowsError(try Store(project).restore(from:bundle,to:dest)) { XCTAssertEqual($0 as? ProofError,.corruptOriginal) }
        XCTAssertFalse(FileManager.default.fileExists(atPath:dest.path))
        try LargeFixture.verify(project,expected:LargeFixture.snapshot())
        let stored=try original(project);XCTAssertEqual(chmod(stored.path,0o600),0)
        let writer=try FileHandle(forWritingTo:stored);try writer.truncate(atOffset:UInt64(LargeFixture.byteCount-1));try writer.close()
        XCTAssertThrowsError(try Store(project).loadFiles()) { XCTAssertEqual($0 as? ProofError,.corruptOriginal) }
        XCTAssertThrowsError(try Store(project).export(to:path("invalid-export")))
        XCTAssertFalse(FileManager.default.fileExists(atPath:path("invalid-export").path))
        print("EVIDENCE LARGE corruption_truncation_explicit=yes invalid_destination_absent=yes")
    }
    func testInterruptedStreamingPreservesCurrentAndRetry() throws {
        for mode in ["denied","noSpace","death"] {
            let base=path(mode);XCTAssertEqual(try cli("large-seed",base),0)
            let project=base.appendingPathComponent("project"),before=try head(project)
            XCTAssertNotEqual(try cli("large-r2",project,"duringOriginalWrite:"+mode),0)
            XCTAssertEqual(try head(project),before)
            try LargeFixture.verify(project,expected:LargeFixture.snapshot())
            let committed=try FileManager.default.contentsOfDirectory(atPath:project.appendingPathComponent("generations").path).filter{$0.hasPrefix("g-")}
            XCTAssertEqual(committed.count,1)
            XCTAssertEqual(try cli("large-r2",project),0)
            let after=try head(project);XCTAssertEqual(try cli("large-r2",project),0)
            XCTAssertEqual(try head(project),after)
            try LargeFixture.verify(project,expected:LargeFixture.snapshot(r2:true))
            print("EVIDENCE LARGE streaming_midwrite \(mode) previous_head_preserved=yes retry_duplicates=0")
        }
    }
    func testFileSourceSymlinkAndMismatchRejectedBeforeStoreExists() throws {
        let source=path("source");try Fixture.original.write(to:source)
        let link=path("link");try FileManager.default.createSymbolicLink(at:link,withDestinationURL:source)
        XCTAssertThrowsError(try Store(path("bad-symlink")).commitFiles(Fixture.r1,sources:["O":link]))
        XCTAssertFalse(FileManager.default.fileExists(atPath:path("bad-symlink").path))
        var wrong=Fixture.r1;wrong.originals=[Original(id:"O",sha256:String(repeating:"0",count:64),byteCount:4096)]
        XCTAssertThrowsError(try Store(path("bad-hash")).commitFiles(wrong,sources:["O":source])) { XCTAssertEqual($0 as? ProofError,.corruptOriginal) }
        XCTAssertFalse(FileManager.default.fileExists(atPath:path("bad-hash").path))
        XCTAssertThrowsError(try Store.describeOriginal(id:"O",source:temp))
        XCTAssertThrowsError(try Store.describeOriginal(id:"../O",source:source))
    }
    func testIncrementalSHA256ChunkBoundariesAndNonDestructiveFinalization() throws {
        for n in [0,1,55,56,63,64,65,127,128,129,65537] {
            let bytes=Data((0..<n).map{UInt8($0%251)})
            for chunk in [1,7,63,64,65,65536] {
                var h=SHA256.Incremental()
                for offset in stride(from:0,to:n,by:chunk) { h.update(bytes.subdata(in:offset..<min(n,offset+chunk))) }
                XCTAssertEqual(h.hex(),SHA256.hex(bytes))
                XCTAssertEqual(h.hex(),SHA256.hex(bytes))
                h.update(Data([1]));XCTAssertEqual(h.hex(),SHA256.hex(bytes+Data([1])))
            }
        }
        XCTAssertEqual(SHA256.hex(Data()),"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(SHA256.hex(Data("abc".utf8)),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
    func testReadOnlyDiagnosticLeavesFilesUnchangedAndTagsFailure() throws {
        let root=path("diagnostic")
        try Store(root).commit(Fixture.r1,payloads:["O":Fixture.original])
        let file=try original(root)
        try FileManager.default.removeItem(at:root.appendingPathComponent(".lock"))
        let priorHead=try head(root),priorOriginal=try Data(contentsOf:file)
        var events=[[String:String]]()
        let diagnostic=Store(root,diagnostic:{events.append($0)})
        XCTAssertEqual(try diagnostic.diagnoseReadOnly(),Fixture.r1)
        XCTAssertEqual(try head(root),priorHead);XCTAssertEqual(try Data(contentsOf:file),priorOriginal)
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent(".lock").path))
        XCTAssertTrue(events.contains{$0["tag"]=="load.CURRENT"})
        XCTAssertTrue(events.contains{$0["tag"]=="load.metadata"})
        XCTAssertTrue(events.contains{$0["tag"]=="digest.end"})
        XCTAssertTrue(events.contains{$0["tag"]=="fstat.after"})
        XCTAssertFalse(events.contains{$0["tag"]?.hasPrefix("reject.")==true})
        XCTAssertEqual(chmod(file.path,0o600),0)
        let writer=try FileHandle(forWritingTo:file);try writer.truncate(atOffset:4000);try writer.close()
        events.removeAll()
        XCTAssertThrowsError(try diagnostic.diagnoseReadOnly()) { XCTAssertEqual($0 as? ProofError,.corruptOriginal) }
        XCTAssertTrue(events.contains{$0["tag"]=="reject.digestSize"})
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent(".lock").path))
    }

    func testMetadataOnlyCtimeChangeRechecksContentOnSameFD() throws {
        let root=path("ctime-metadata")
        try Store(root).commit(Fixture.r1,payloads:["O":Fixture.original])
        let file=try original(root),priorHead=try head(root)
        var events=[[String:String]](),currentFile="",changed=false
        let store=Store(root,diagnostic:{ event in
            events.append(event)
            if event["tag"]=="open" { currentFile=event["file"] ?? "" }
            if event["tag"]=="fstat.before",currentFile=="O.bin",!changed {
                changed=true
                // Own temporary fixture only. chmod changes ctime, not original bytes/mtime.
                XCTAssertEqual(chmod(file.path,0o600),0)
            }
        })
        XCTAssertEqual(try store.loadFiles().0,Fixture.r1)
        XCTAssertTrue(changed)
        XCTAssertTrue(events.contains{$0["tag"]=="metadata.ctimeChanged"})
        XCTAssertTrue(events.contains{$0["tag"]=="content.recheck.pass"})
        XCTAssertEqual(try Data(contentsOf:file),Fixture.original)
        XCTAssertEqual(try head(root),priorHead)
    }
    func testContentChangeWithRestoredMtimeRejectedByCtimeRecheck() throws {
        let root=path("ctime-content")
        try Store(root).commit(Fixture.r1,payloads:["O":Fixture.original])
        let file=try original(root)
        XCTAssertEqual(chmod(file.path,0o600),0)
        var before=stat();XCTAssertEqual(stat(file.path,&before),0)
        var events=[[String:String]](),changed=false
        let store=Store(root,diagnostic:{ event in
            events.append(event)
            if event["tag"]=="digest.end",!changed {
                changed=true
                // Alter bytes AFTER first valid hash, restore exact mtime, preserve size.
                let writer=open(file.path,O_WRONLY|O_NOFOLLOW)
                XCTAssertGreaterThanOrEqual(writer,0)
                var byte:UInt8=0
                XCTAssertEqual(pwrite(writer,&byte,1,0),1)
                var times=[before.st_atimespec,before.st_mtimespec]
                XCTAssertEqual(times.withUnsafeMutableBufferPointer { futimens(writer,$0.baseAddress!) },0)
                XCTAssertEqual(close(writer),0)
            }
        })
        XCTAssertThrowsError(try store.loadFiles()) { XCTAssertEqual($0 as? ProofError,.corruptOriginal) }
        XCTAssertTrue(changed)
        XCTAssertTrue(events.contains{$0["tag"]=="metadata.ctimeChanged"})
        XCTAssertTrue(events.contains{$0["tag"]=="reject.contentRecheckHash"})
        XCTAssertFalse(events.contains{$0["tag"]=="content.recheck.pass"})
    }

}
