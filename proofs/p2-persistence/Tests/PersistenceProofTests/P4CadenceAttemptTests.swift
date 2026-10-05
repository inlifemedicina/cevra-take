import XCTest
import ManualTextProof
@testable import PersistenceProof

// Synthetic files/capabilities only. No device, AVFoundation, or historical media.
final class P4CadenceAttemptTests:XCTestCase {
    private let scope=P3AttemptScope.cadenceValidation
    private let mode=P4VideoMode(width:1920,height:1080,fps:30)
    private let mic=P4MicrophoneCapability(id:"synthetic-mic",name:"Synthetic input",kind:"MicrophoneBuiltIn")
    private func config(fps:Int=30)->P4CaptureConfiguration {
        let selected=P4VideoMode(width:1920,height:1080,fps:fps)
        let camera=P4CameraCapability(id:"synthetic-front",position:.front,modes:[selected])
        return .init(camera:camera,mode:selected,axis:.vertical,previewMirrored:true,originalMirrored:false,microphone:mic)
    }
    private func temporaryRoot() throws -> URL {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("cadence002-fixture-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        return root
    }
    private func report(_ original:Original,attempt:P3AttemptScope,profile:String)->[String:String] {
        var value=config().report
        value.merge(["attempt":attempt.rawValue,"profile":profile,"sha256":original.sha256,"bytes":String(original.byteCount),
                     "nominalFPS":"29.998332977294922"]) { _,new in new }
        if attempt == scope { value.merge(["profileCriteriaVersion":P4CadenceResult.version,"timestampAverageFPS":"30"]) { _,new in new } }
        return value
    }
    func testOnlyFixedVersionedNewScopeCanCaptureAndOldScopesStayReadOnly() {
        let root=URL(fileURLWithPath:"/synthetic/P3CaptureSandbox")
        XCTAssertEqual(scope.rawValue,"P4-30FPS-CADENCE-002-ATTEMPT-001")
        XCTAssertTrue(scope.allowsCapture);XCTAssertTrue(scope.requiresInstructions);XCTAssertTrue(scope.requiresPreview)
        for old in [P3AttemptScope.original,.retry001,.retry002,.vertical,.horizontal,.horizontalResume,.manualTextVertical,.manualTextFrontVertical,.cameraSettings] {
            XCTAssertFalse(old.allowsCapture);XCTAssertFalse(old.acceptsCaptureConfiguration(config()))
            XCTAssertNotEqual(old.base(in:root),scope.base(in:root))
        }
        XCTAssertEqual(scope.base(in:root),root.appendingPathComponent(scope.rawValue,isDirectory:true))
    }
    func testNoMissingNonThirtyOrUnlistedModeCanPrepareOrStart() {
        XCTAssertTrue(scope.acceptsCaptureConfiguration(config()))
        XCTAssertFalse(scope.acceptsCaptureConfiguration(nil))
        for fps in [24,25,50,60,120] { XCTAssertFalse(scope.acceptsCaptureConfiguration(config(fps:fps))) }
        let c=config(),empty=P4CameraCapability(id:c.camera.id,position:.front,modes:[])
        let unlisted=P4CaptureConfiguration(camera:empty,mode:mode,axis:c.axis,previewMirrored:true,originalMirrored:false,microphone:mic)
        XCTAssertFalse(scope.acceptsCaptureConfiguration(unlisted))
        XCTAssertFalse(c.appliedMatches(cameraID:c.camera.id,mode:mode,minimumDuration:1/24,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(c.mayStart(free:P3Limits.startSpace,inputIDs:["wrong-route"],permissions:true,thermalSafe:true))
    }
    func testConsentAndPauseResumeRejectStaleEpochAndDoNotReserveBeforeAdmission() throws {
        var consent=P3PreparationConsent(scope:scope),epoch=P3PreviewEpoch(),gate=P3StartClaimGate(),writes=0
        XCTAssertFalse(consent.mayPrepare(phase:.idle));consent.acknowledgeInstructions();XCTAssertTrue(consent.mayPrepare(phase:.idle))
        let old=epoch.begin();consent.observePreview(ready:true)
        XCTAssertFalse(try gate.reserve(admitted:consent.mayRecord(phase:.ready,sessionRunning:true)) { writes += 1 })
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:false))
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        epoch.cancel();consent.observePreview(ready:false);let fresh=epoch.begin()
        XCTAssertFalse(epoch.accepts(old));XCTAssertTrue(epoch.accepts(fresh))
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        consent.observePreview(ready:true);XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        let frame=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:config().policy)
        let changed=P3OrientationFrame(posture:.portraitUpsideDown,previewAngle:270,captureAngle:270,cameraPolicy:config().policy)
        XCTAssertFalse(P3OrientationStartTransaction.admitted(frame,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(P3OrientationStartTransaction.admitted(frame,latest:frame,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(try gate.reserve(admitted:epoch.accepts(fresh) && consent.mayRecord(phase:.ready,sessionRunning:true)) { writes += 1 })
        XCTAssertFalse(try gate.reserve(admitted:true) { writes += 1 });XCTAssertEqual(writes,1)
    }
    func testNewClaimDoesNotModifyConsumedOldClaimResultOrOriginal() throws {
        let root=try temporaryRoot();defer { try? FileManager.default.removeItem(at:root) }
        let old=P3AttemptScope.cameraSettings.base(in:root),new=scope.base(in:root)
        try FileManager.default.createDirectory(at:old,withIntermediateDirectories:false)
        let fixture=["ATTEMPT-RESERVED.json":Data("consumed old claim".utf8),"result.json":Data("historical FAIL unchanged".utf8),"O.bin":Fixture.original]
        for (name,bytes) in fixture { try bytes.write(to:old.appendingPathComponent(name)) }
        XCTAssertFalse(FileManager.default.fileExists(atPath:new.path))
        var gate=P3StartClaimGate();XCTAssertFalse(try gate.reserve(admitted:false) { XCTFail("Pre-start write") })
        XCTAssertFalse(FileManager.default.fileExists(atPath:new.path))
        XCTAssertTrue(try gate.reserve(admitted:scope.acceptsCaptureConfiguration(config())) {
            try FileManager.default.createDirectory(at:new,withIntermediateDirectories:false)
            try Data(scope.rawValue.utf8).write(to:new.appendingPathComponent("ATTEMPT-RESERVED.json"),options:.withoutOverwriting)
        })
        for (name,bytes) in fixture { XCTAssertEqual(try Data(contentsOf:old.appendingPathComponent(name)),bytes) }
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath:old.path)),Set(fixture.keys))
    }
    func testFailureAfterExclusiveClaimRetainsItAndFreshControllerCannotRetry() throws {
        let root=try temporaryRoot();defer { try? FileManager.default.removeItem(at:root) }
        let new=scope.base(in:root),claim=new.appendingPathComponent("ATTEMPT-RESERVED.json")
        var gate=P3StartClaimGate()
        XCTAssertThrowsError(try gate.reserve(admitted:true) {
            try FileManager.default.createDirectory(at:new,withIntermediateDirectories:false)
            try Data(scope.rawValue.utf8).write(to:claim,options:.withoutOverwriting)
            throw CocoaError(.fileWriteOutOfSpace)
        })
        let before=try Data(contentsOf:claim)
        var fresh=P3StartClaimGate(),state=P3State()
        XCTAssertTrue(state.accept(.fail));XCTAssertFalse(state.accept(.prepare));XCTAssertFalse(state.accept(.resume))
        XCTAssertThrowsError(try fresh.reserve(admitted:true) { try Data("replacement".utf8).write(to:claim,options:.withoutOverwriting) })
        XCTAssertEqual(try Data(contentsOf:claim),before)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:new.path),["ATTEMPT-RESERVED.json"])
    }
    func testReopenUsesMatchingAttemptCriteriaAndOriginalWithoutReclassifyingOldFail() {
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:4096)
        let old=report(original,attempt:.cameraSettings,profile:"FAIL"),new=report(original,attempt:scope,profile:"PASS")
        XCTAssertEqual(P3FileFeedback.recorded(old,matching:original,requiresSettingsReport:true).profile,.fail)
        XCTAssertNil(P3FileFeedback.recorded(old,matching:original,requiresSettingsReport:true).independentlyMeasuredAverageFPS)
        let current=P3FileFeedback.recorded(new,matching:original,requiresSettingsReport:true,settingsScope:scope)
        XCTAssertEqual(current.profile,.pass);XCTAssertEqual(current.configuredFPS,30);XCTAssertEqual(current.independentlyMeasuredAverageFPS,30)
        XCTAssertEqual(P3FileFeedback.recorded(old,matching:original,requiresSettingsReport:true,settingsScope:scope).profile,.unavailable)
        XCTAssertEqual(P3FileFeedback.recorded(new,matching:original,requiresSettingsReport:true).profile,.unavailable)
        XCTAssertEqual(old["profile"],"FAIL");XCTAssertNil(old["profileCriteriaVersion"])
        for (key,value) in [("attempt",P3AttemptScope.cameraSettings.rawValue),("profileCriteriaVersion","old"),("configuredFPS","24"),("appliedFPS","24"),("sha256",String(repeating:"b",count:64))] {
            var wrong=new;wrong[key]=value
            XCTAssertEqual(P3FileFeedback.recorded(wrong,matching:original,requiresSettingsReport:true,settingsScope:scope).profile,.unavailable)
        }
        XCTAssertNotNil(P4RecordedSettings(report:new,expectedAttempt:scope))
        XCTAssertNil(P4RecordedSettings(report:old,expectedAttempt:scope))
    }
    func testSeparateStoreReopenKeepsBindingAndOldNamespaceByteExact() throws {
        let root=try temporaryRoot();defer { try? FileManager.default.removeItem(at:root) }
        let old=P3AttemptScope.cameraSettings.base(in:root);try FileManager.default.createDirectory(at:old,withIntermediateDirectories:false)
        let oldFile=old.appendingPathComponent("result.json"),oldBytes=Data("synthetic historical FAIL".utf8);try oldBytes.write(to:oldFile)
        let binding=try P4CaptureBinding.fixedPT(),bytes=Fixture.original
        let original=Original(id:"O",sha256:SHA256.hex(bytes),byteCount:bytes.count)
        try FileManager.default.createDirectory(at:scope.base(in:root),withIntermediateDirectories:false)
        let destination=scope.base(in:root).appendingPathComponent("project")
        try Store(destination).commit(binding.snapshot(original),payloads:["O":bytes])
        let (snapshot,reopened)=try Store(destination).load()
        XCTAssertTrue(binding.matches(snapshot));XCTAssertEqual(reopened["O"],bytes)
        XCTAssertEqual(try Data(contentsOf:oldFile),oldBytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:old.path),["result.json"])
    }
    func testOldMinimalSettingsFeedbackContractRemainsUnchanged() {
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:4096)
        let old=["attempt":P3AttemptScope.cameraSettings.rawValue,"settingsVersion":P3AttemptScope.cameraSettings.rawValue,
                 "profile":"FAIL","configuredFPS":"30","nominalFPS":"29.998332977294922","sha256":original.sha256,"bytes":"4096"]
        let feedback=P3FileFeedback.recorded(old,matching:original,requiresSettingsReport:true)
        XCTAssertEqual(feedback.profile,.fail);XCTAssertEqual(feedback.configuredFPS,30)
        XCTAssertNil(feedback.independentlyMeasuredAverageFPS)
        var wrong=old;wrong["attempt"]=scope.rawValue
        XCTAssertEqual(P3FileFeedback.recorded(wrong,matching:original,requiresSettingsReport:true,settingsScope:scope).profile,.unavailable)
    }
    func testFreshPreparationIdentityDoesNotCreateNewAttemptNamespace() throws {
        let a=P4SettingsPreparation(configuration:config()),b=P4SettingsPreparation(configuration:config())
        XCTAssertNotEqual(a.id,b.id);XCTAssertEqual(a.configuration,b.configuration)
        let root=URL(fileURLWithPath:"/synthetic/P3CaptureSandbox")
        XCTAssertEqual(scope.base(in:root),P3AttemptScope.cadenceValidation.base(in:root))
        XCTAssertFalse(P4VideoMode(width:1920,height:1080,fps:30).fileProfile(duration:30,width:1920,height:1080,fps:29.998332977294922,videoTracks:1,audioTracks:1,sdr:true))
    }
}
