import XCTest
@testable import PersistenceProof

final class P3RulesTests: XCTestCase {
    func testNoImplicitStartAndDuplicateCommands() {
        var s=P3State(); XCTAssertEqual(s.phase,.idle)
        XCTAssertFalse(s.accept(.record)); XCTAssertFalse(s.accept(.started))
        XCTAssertTrue(s.accept(.prepare)); XCTAssertFalse(s.accept(.prepare))
        XCTAssertTrue(s.accept(.permitted)); XCTAssertTrue(s.accept(.prepared))
        XCTAssertTrue(s.accept(.record)); XCTAssertFalse(s.accept(.record))
        XCTAssertTrue(s.accept(.started)); XCTAssertTrue(s.accept(.stop))
        XCTAssertFalse(s.accept(.stop)); XCTAssertTrue(s.accept(.finished))
        XCTAssertTrue(s.accept(.persisted)); XCTAssertFalse(s.accept(.record))
    }
    func testExplicitRecoveryDoesNotStartRecording() {
        var s=P3State();XCTAssertTrue(s.accept(.recovered));XCTAssertEqual(s.phase,.saved)
        XCTAssertFalse(s.accept(.record));XCTAssertFalse(s.accept(.prepare))
    }
    func testFailAndAutoStopNeverResumeOrSaveEarly() {
        var s=P3State(); XCTAssertFalse(s.accept(.persisted))
        XCTAssertTrue(s.accept(.fail)); XCTAssertFalse(s.accept(.record)); XCTAssertFalse(s.accept(.prepare))
        XCTAssertEqual(s.phase,.failed)
    }
    func testSpacePermissionRouteThermalFailClosed() {
        let enough=P3Limits.startSpace
        XCTAssertTrue(P3Limits.mayStart(free:enough,internalMic:true,permissions:true,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:enough-1,internalMic:true,permissions:true,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:nil,internalMic:true,permissions:true,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:enough,internalMic:false,permissions:true,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:enough,internalMic:true,permissions:false,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:enough,internalMic:true,permissions:true,thermalSafe:false))
    }
    func testFileProfileBoundariesNo2997OrUnknownSDR() {
        func valid(_ duration:Double=30,_ fps:Double=30,_ sdr:Bool=true,_ audio:Int=1)->Bool {
            P3Limits.fileProfile(duration:duration,width:1920,height:1080,fps:fps,videoTracks:1,audioTracks:audio,sdrVerified:sdr)
        }
        XCTAssertTrue(valid(29)); XCTAssertTrue(valid(31)); XCTAssertFalse(valid(28.999)); XCTAssertFalse(valid(31.001))
        XCTAssertFalse(valid(30,29.97)); XCTAssertFalse(valid(30,30,false)); XCTAssertFalse(valid(30,30,true,0)); XCTAssertFalse(valid(.nan))
    }
    func testP3RealMetadataAndP2SyntheticSeparation() throws {
        try Fixture.r1.validate(); try LargeFixture.snapshot().validate()
        let o=Original(id:"O",sha256:Fixture.r1.originals[0].sha256,byteCount:4096)
        let p3=P3Limits.snapshot(o); try p3.validate(); XCTAssertFalse(p3.takes[0].synthetic)
        let badP2=Snapshot(formatVersion:1,projectID:"P2-FIXTURE-001",revisions:p3.revisions,takes:p3.takes,originals:p3.originals)
        XCTAssertThrowsError(try badP2.validate())
        let badP3=Snapshot(formatVersion:1,projectID:"P3-CAPTURE-001",revisions:Fixture.r1.revisions,takes:Fixture.r1.takes,originals:Fixture.r1.originals)
        XCTAssertThrowsError(try badP3.validate())
        let foreign=Snapshot(formatVersion:1,projectID:"P3-OTHER",revisions:p3.revisions,takes:p3.takes,originals:p3.originals)
        XCTAssertThrowsError(try foreign.validate())
        let zero=P3Limits.snapshot(Original(id:"O",sha256:o.sha256,byteCount:0))
        XCTAssertThrowsError(try zero.validate())
        let wrongRevision=Snapshot(formatVersion:1,projectID:p3.projectID,revisions:[Revision(id:"R2",scriptID:"S",text:"test")],takes:p3.takes,originals:p3.originals)
        XCTAssertThrowsError(try wrongRevision.validate())
        let multiple=Snapshot(formatVersion:1,projectID:p3.projectID,revisions:p3.revisions,takes:p3.takes+p3.takes,originals:p3.originals)
        XCTAssertThrowsError(try multiple.validate())
    }
    func testStopBeforeStartKeepsDeadlineAndRejectsLateCallbacks() {
        var d=P3RecordingDeadline();XCTAssertTrue(d.begin());XCTAssertTrue(d.requestStop())
        XCTAssertTrue(d.startExpired());XCTAssertTrue(d.invalidated)
        XCTAssertFalse(d.startCallback());XCTAssertFalse(d.finishCallback())
    }
    func testStopAfterStartWithoutFinishTimesOutAndBackgroundInvalidates() {
        var d=P3RecordingDeadline();XCTAssertTrue(d.begin());XCTAssertTrue(d.startCallback())
        XCTAssertTrue(d.requestStop());XCTAssertTrue(d.finishExpired());XCTAssertFalse(d.finishCallback())
        var background=P3RecordingDeadline();XCTAssertTrue(background.begin());XCTAssertTrue(background.requestStop())
        background.cancel();XCTAssertFalse(background.startCallback());XCTAssertFalse(background.finishCallback())
    }
    func testAbsentAutomaticFinishHasDeadlineAndNoLateSuccess() {
        var d=P3RecordingDeadline();XCTAssertTrue(d.begin());XCTAssertTrue(d.startCallback())
        XCTAssertTrue(d.completionExpired());XCTAssertFalse(d.finishCallback())
    }
    func testNormalFinishDisarmsDeadlinesAndDuplicateCallbacks() {
        var d=P3RecordingDeadline();XCTAssertTrue(d.begin());XCTAssertTrue(d.startCallback())
        XCTAssertTrue(d.requestStop());XCTAssertTrue(d.finishCallback());XCTAssertTrue(d.finished)
        XCTAssertFalse(d.startExpired());XCTAssertFalse(d.finishExpired());XCTAssertFalse(d.completionExpired());XCTAssertFalse(d.finishCallback())
    }
    func testP3FilePersistenceUsesUnchangedStoreWithRealFlag() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:dir) }
        let file=dir.appendingPathComponent("test-input.bin"); try Fixture.original.write(to:file,options:.withoutOverwriting)
        let o=try Store.describeOriginal(id:"O",source:file)
        let s=P3Limits.snapshot(o); let root=dir.appendingPathComponent("project")
        try Store(root).commitFiles(s,sources:["O":file])
        let loaded=try Store(root).loadFiles(); XCTAssertEqual(loaded.0,s)
        XCTAssertEqual(try Data(contentsOf:loaded.1["O"]!),Fixture.original)
        XCTAssertTrue(FileManager.default.fileExists(atPath:file.path))
        let process=Process()
        process.executableURL=URL(fileURLWithPath:try XCTUnwrap(ProcessInfo.processInfo.environment["P2_PROOF_EXECUTABLE"]))
        process.arguments=["verify",root.path];let out=Pipe();process.standardOutput=out
        try process.run();let bytes=out.fileHandleForReading.readDataToEndOfFile();process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus,0);XCTAssertEqual(bytes,try canonical(s))
    }
}
