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


extension P3RulesTests {
    func testFixedAttemptNamespacesPreserveExistingRecords() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        let original=P3AttemptScope.original.base(in:root),old=P3AttemptScope.retry001.base(in:root),fresh=P3AttemptScope.retry002.base(in:root)
        XCTAssertEqual(original,root);XCTAssertNotEqual(old,fresh)
        XCTAssertNil(P3AttemptScope(rawValue:"P3-RETRY-003"))
        try FileManager.default.createDirectory(at:old,withIntermediateDirectories:false)
        let originalPointer=original.appendingPathComponent("LATEST.json"),oldClaim=old.appendingPathComponent("ATTEMPT-RESERVED.json")
        let a=Data("original-pointer".utf8),b=Data("consumed-001".utf8)
        try a.write(to:originalPointer);try b.write(to:oldClaim)
        XCTAssertFalse(FileManager.default.fileExists(atPath:fresh.path))
        try FileManager.default.createDirectory(at:fresh,withIntermediateDirectories:false)
        try Data("new-authorized-002".utf8).write(to:fresh.appendingPathComponent("ATTEMPT-RESERVED.json"))
        XCTAssertEqual(try Data(contentsOf:originalPointer),a)
        XCTAssertEqual(try Data(contentsOf:oldClaim),b)
    }
    func test002NeedsInstructionsAndRealPreviewConfirmationBeforeRecording() {
        var consent=P3PreparationConsent(scope:.retry002)
        XCTAssertFalse(consent.mayPrepare(phase:.idle))
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        consent.acknowledgeInstructions()
        XCTAssertTrue(consent.mayPrepare(phase:.idle))
        XCTAssertFalse(consent.mayPrepare(phase:.permission))
        consent.observePreview(ready:true)
        XCTAssertFalse(consent.confirmPreview(phase:.preparing,sessionRunning:true,humanVisible:true))
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:false,humanVisible:true))
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:false))
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(consent.mayRecord(phase:.ready,sessionRunning:true))
        XCTAssertFalse(consent.mayRecord(phase:.starting,sessionRunning:true))
        consent.observePreview(ready:false)
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        consent.observePreview(ready:true)
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true)) // no stale human consent
    }
    func testConsentInvalidationCannotResumeAfterInterruptionOrReentry() {
        var consent=P3PreparationConsent(scope:.retry002)
        consent.acknowledgeInstructions();consent.observePreview(ready:true)
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        consent.invalidate()
        consent.acknowledgeInstructions();consent.observePreview(ready:true)
        XCTAssertFalse(consent.mayPrepare(phase:.idle))
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
    }
}


extension P3RulesTests {
    func testOrientationRecognizesBothAxesAndRejectsFlatOrUnknownDevice() {
        XCTAssertEqual(P3Posture.device(rawValue:1),.portrait)
        XCTAssertEqual(P3Posture.device(rawValue:2),.portraitUpsideDown)
        XCTAssertEqual(P3Posture.device(rawValue:3),.landscapePortRight)
        XCTAssertEqual(P3Posture.device(rawValue:4),.landscapePortLeft)
        for raw in [0,5,6,99] { XCTAssertNil(P3Posture.device(rawValue:raw).axis) }
        for posture in [P3Posture.portrait,.portraitUpsideDown,.landscapePortLeft,.landscapePortRight] {
            let f=P3OrientationFrame(posture:posture,previewAngle:90,captureAngle:180)
            XCTAssertTrue(f.supported(for:posture.axis,previewSupported:true,captureSupported:true))
            XCTAssertFalse(f.supported(for:posture.axis == .vertical ? .horizontal : .vertical,previewSupported:true,captureSupported:true))
        }
    }
    func testNativePreviewCapturePairNeedNotHaveEqualAnglesButMustBothBeSupported() {
        let f=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:180)
        XCTAssertTrue(f.supported(for:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertFalse(f.supported(for:.vertical,previewSupported:false,captureSupported:true))
        XCTAssertFalse(f.supported(for:.vertical,previewSupported:true,captureSupported:false))
        XCTAssertFalse(f.supported(for:nil,previewSupported:true,captureSupported:true))
        XCTAssertFalse(P3OrientationFrame(posture:.unknown,previewAngle:0,captureAngle:0).supported(for:.vertical,previewSupported:true,captureSupported:true))
        for bad in [Double.nan,Double.infinity,-1,360] {
            XCTAssertFalse(P3OrientationFrame(posture:.portrait,previewAngle:bad,captureAngle:90).supported(for:.vertical,previewSupported:true,captureSupported:true))
            XCTAssertFalse(P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:bad).supported(for:.vertical,previewSupported:true,captureSupported:true))
        }
    }
    func testOrientationCannotFreezeUnsupportedAndCannotRotateFrozenClip() {
        let vertical=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90)
        let horizontal=P3OrientationFrame(posture:.landscapePortRight,previewAngle:0,captureAngle:0)
        var lock=P3OrientationFreeze()
        XCTAssertFalse(lock.lock(horizontal,axis:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertNil(lock.frame)
        XCTAssertFalse(lock.lock(vertical,axis:.vertical,previewSupported:true,captureSupported:false))
        XCTAssertNil(lock.frame)
        XCTAssertTrue(lock.lock(vertical,axis:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertFalse(lock.lock(horizontal,axis:.horizontal,previewSupported:true,captureSupported:true))
        XCTAssertFalse(lock.lock(vertical,axis:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertEqual(lock.frame,vertical)
    }
    func testOrientationProofsHaveExactlyTwoFixedDistinctNamespacesAndHumanGates() {
        let root=URL(fileURLWithPath:"/unused-test-root")
        let scopes:[P3AttemptScope]=[.original,.retry001,.retry002,.vertical,.horizontal]
        XCTAssertEqual(Set(scopes.map { $0.base(in:root).path }).count,5)
        XCTAssertEqual(scopes.filter(\.isOrientationProof),[.vertical,.horizontal])
        XCTAssertNil(P3AttemptScope(rawValue:"P3-ORIENTATION-VERTICAL-002"))
        for scope in [P3AttemptScope.vertical,.horizontal] {
            var c=P3PreparationConsent(scope:scope)
            XCTAssertFalse(c.mayPrepare(phase:.idle));c.acknowledgeInstructions()
            XCTAssertTrue(c.mayPrepare(phase:.idle));c.observePreview(ready:true)
            XCTAssertFalse(c.mayRecord(phase:.ready,sessionRunning:true))
            XCTAssertTrue(c.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
            XCTAssertTrue(c.mayRecord(phase:.ready,sessionRunning:true))
            c.observePreview(ready:false) // unknown posture, changed pair or lost preview clears the human gate
            c.observePreview(ready:true)
            XCTAssertFalse(c.mayRecord(phase:.ready,sessionRunning:true))
        }
    }
}

extension P3RulesTests {
    func testOrientationChangeBetweenHumanConfirmationAndSerialAdmissionDoesNotConsumeFreeze() {
        let first=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90)
        let changed=P3OrientationFrame(posture:.portraitUpsideDown,previewAngle:270,captureAngle:270)
        var consent=P3PreparationConsent(scope:.vertical);consent.acknowledgeInstructions();consent.observePreview(ready:true)
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        var transaction=P3OrientationStartTransaction()
        XCTAssertTrue(transaction.propose(first,axis:.vertical,previewSupported:true))
        XCTAssertFalse(transaction.propose(first,axis:.vertical,previewSupported:true)) // duplicate while pending
        consent.observePreview(ready:false);consent.observePreview(ready:true)
        XCTAssertFalse(P3OrientationStartTransaction.admitted(first,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(transaction.finish(accepted:false));XCTAssertNil(transaction.frame)
        XCTAssertFalse(transaction.finish(accepted:true)) // stale completion cannot commit rejected proposal
        XCTAssertFalse(P3OrientationStartTransaction.admitted(changed,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(transaction.propose(changed,axis:.vertical,previewSupported:true))
        XCTAssertTrue(P3OrientationStartTransaction.admitted(changed,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(transaction.finish(accepted:true));XCTAssertEqual(transaction.committed,changed)
        XCTAssertFalse(transaction.propose(first,axis:.vertical,previewSupported:true)) // no second clip after commit
        XCTAssertFalse(transaction.finish(accepted:false));XCTAssertEqual(transaction.frame,changed)
    }
}

extension P3RulesTests {
    func testPreRecordingPauseResumeRequiresHumanTransitionAndFreshConfirmation() {
        var s=P3State();var c=P3PreparationConsent(scope:.horizontalResume)
        c.acknowledgeInstructions();XCTAssertTrue(s.accept(.prepare));XCTAssertFalse(s.accept(.prepare))
        XCTAssertTrue(s.accept(.permitted));XCTAssertTrue(s.accept(.prepared))
        c.observePreview(ready:true);XCTAssertTrue(c.confirmPreview(phase:s.phase,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(s.accept(.pause));c.observePreview(ready:false)
        XCTAssertFalse(s.accept(.pause));XCTAssertFalse(s.accept(.record));XCTAssertFalse(s.accept(.prepared))
        XCTAssertFalse(c.mayRecord(phase:s.phase,sessionRunning:true))
        XCTAssertTrue(s.accept(.resume));XCTAssertFalse(s.accept(.resume));XCTAssertFalse(s.accept(.record))
        XCTAssertTrue(s.accept(.permitted));XCTAssertTrue(s.accept(.prepared));c.observePreview(ready:true)
        XCTAssertFalse(c.mayRecord(phase:s.phase,sessionRunning:true))
        XCTAssertFalse(c.confirmPreview(phase:s.phase,sessionRunning:false,humanVisible:true))
        XCTAssertFalse(c.confirmPreview(phase:s.phase,sessionRunning:true,humanVisible:false))
        XCTAssertTrue(c.confirmPreview(phase:s.phase,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(s.accept(.record));XCTAssertFalse(s.accept(.record))
        XCTAssertFalse(s.accept(.pause));XCTAssertFalse(s.accept(.resume)) // recording cannot resume/segment
        XCTAssertTrue(s.accept(.fail));XCTAssertFalse(s.accept(.resume));XCTAssertFalse(s.accept(.record))
    }
    func testPermissionOrPreparingPauseCancelsEpochAndNoObsoleteCallbackCanResume() {
        for beforePause in [P3Phase.permission,.preparing,.ready] {
            var state=P3State();var epoch=P3PreviewEpoch()
            XCTAssertTrue(state.accept(.prepare));let first=epoch.begin()
            if beforePause != .permission { XCTAssertTrue(state.accept(.permitted)) }
            if beforePause == .ready { XCTAssertTrue(state.accept(.prepared)) }
            XCTAssertTrue(epoch.accepts(first));XCTAssertTrue(state.accept(.pause));epoch.cancel()
            XCTAssertFalse(epoch.accepts(first));XCTAssertFalse(state.accept(.prepared))
            XCTAssertTrue(state.accept(.resume));let second=epoch.begin()
            XCTAssertFalse(epoch.accepts(first));XCTAssertTrue(epoch.accepts(second))
            epoch.cancel();XCTAssertFalse(epoch.accepts(second))
        }
    }
    func testExclusiveStartOperationNeverRunsOnUnadmittedStartAndOnlyRunsOnce() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let claim=root.appendingPathComponent("ATTEMPT-RESERVED.json")
        var gate=P3StartClaimGate(),calls=0
        let write:() throws -> Void = { calls += 1;try Data("unique-start-claim".utf8).write(to:claim,options:.withoutOverwriting) }
        XCTAssertFalse(try gate.reserve(admitted:false,exclusiveWrite:write))
        XCTAssertFalse(FileManager.default.fileExists(atPath:claim.path));XCTAssertEqual(calls,0)
        XCTAssertTrue(try gate.reserve(admitted:true,exclusiveWrite:write))
        XCTAssertFalse(try gate.reserve(admitted:true,exclusiveWrite:write));XCTAssertEqual(calls,1)
        XCTAssertEqual(try Data(contentsOf:claim),Data("unique-start-claim".utf8))
        // A fresh process/gate cannot bypass the persistent exclusive claim.
        var fresh=P3StartClaimGate();XCTAssertThrowsError(try fresh.reserve(admitted:true,exclusiveWrite:write))
        XCTAssertEqual(try Data(contentsOf:claim),Data("unique-start-claim".utf8))
    }
    func testClaimWriteFailureRemainsConsumedOnDiskWithoutDeletingOrRetrying() throws {
        enum Fault:Error { case injected }
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let claim=root.appendingPathComponent("ATTEMPT-RESERVED.json");var gate=P3StartClaimGate()
        XCTAssertThrowsError(try gate.reserve(admitted:true) {
            try Data("partial-claim-preserved".utf8).write(to:claim,options:.withoutOverwriting);throw Fault.injected
        })
        XCTAssertFalse(gate.claimed);XCTAssertEqual(try Data(contentsOf:claim),Data("partial-claim-preserved".utf8))
        var state=P3State();XCTAssertTrue(state.accept(.fail));XCTAssertFalse(state.accept(.resume))
        // No RUN is allocated by the pure claim gate, including write failure.
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.path),["ATTEMPT-RESERVED.json"])
    }
    func testFreshResumeNamespaceDoesNotReclaimHistoricalHorizontalOrRepeatVertical() {
        let root=URL(fileURLWithPath:"/unused-test-root")
        let fresh=P3AttemptScope.horizontalResume
        XCTAssertEqual(fresh.rawValue,"P3-PREVIEW-RESUME-HORIZONTAL-001")
        XCTAssertEqual(fresh.axis,.horizontal);XCTAssertTrue(fresh.requiresInstructions)
        for old in [P3AttemptScope.original,.retry001,.retry002,.vertical,.horizontal] {
            XCTAssertNotEqual(fresh.base(in:root),old.base(in:root))
        }
        XCTAssertNil(P3AttemptScope(rawValue:"P3-PREVIEW-RESUME-HORIZONTAL-002"))
    }
}
