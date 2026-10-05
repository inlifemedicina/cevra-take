import XCTest
@testable import PersistenceProof

// Pure protocol regressions with synthetic capabilities/files. These do not
// instantiate SwiftUI/AVFoundation or establish physical controller behavior.
final class P4CameraSettingsAdversarialTests:XCTestCase {
    private let mode=P4VideoMode(width:1920,height:1080,fps:30)
    private let mic=P4MicrophoneCapability(id:"fixture-input",name:"Synthetic input",kind:"MicrophoneBuiltIn")
    private var back:P4CameraCapability { .init(id:"fixture-back",position:.back,modes:[mode]) }
    private var front:P4CameraCapability { .init(id:"fixture-front",position:.front,modes:[mode]) }
    private func draft(_ camera:P4CameraCapability,axis:P3OrientationAxis)->P4SettingsDraft {
        var d=P4SettingsDraft();d.chooseCamera(camera.id);d.mode=mode;d.microphoneID=mic.id;d.axis=axis
        return d
    }

    func testRepeatedConfirmationCannotReplaceSnapshotUntilReturningToEdit() throws {
        var d=draft(back,axis:.horizontal);d.previewMirrored=false;d.originalMirrored=true
        let b=P4SettingsPreparation(configuration:try XCTUnwrap(d.commit(cameras:[back,front],microphones:[mic])))
        for _ in 0..<16 { XCTAssertNil(d.commit(cameras:[back,front],microphones:[mic])) }
        XCTAssertEqual(d.committed,b.configuration)
        d.returnToEditing();d.chooseCamera(front.id);d.mode=mode;d.axis = .vertical
        d.previewMirrored=true;d.originalMirrored=false
        let a=P4SettingsPreparation(configuration:try XCTUnwrap(d.commit(cameras:[back,front],microphones:[mic])))
        XCTAssertNotEqual(a.id,b.id);XCTAssertEqual(a.configuration.camera.position,.front)
        XCTAssertEqual(a.configuration.axis,.vertical);XCTAssertTrue(a.configuration.previewMirrored)
        XCTAssertFalse(a.configuration.originalMirrored);XCTAssertEqual(a.configuration.microphone,mic)
        XCTAssertEqual(b.configuration.camera.position,.back);XCTAssertEqual(b.configuration.axis,.horizontal)
        XCTAssertFalse(b.configuration.previewMirrored);XCTAssertTrue(b.configuration.originalMirrored)
        XCTAssertEqual(b.configuration.positionText(.pt),"Posição deste preparo: Horizontal")
        let rerender=a;XCTAssertEqual(rerender.id,a.id);XCTAssertEqual(rerender.configuration,a.configuration)
    }

    func testReturnToEditingRejectsStaleCapabilitiesWithoutMutatingPriorPreparation() throws {
        var d=draft(back,axis:.horizontal)
        let old=try XCTUnwrap(d.commit(cameras:[back],microphones:[mic]))
        d.axis = .vertical;d.mode=P4VideoMode(width:3840,height:2160,fps:60);d.microphoneID="missing"
        XCTAssertEqual(d.committed,old)
        d.returnToEditing();d.chooseCamera(front.id)
        XCTAssertNil(d.mode);XCTAssertEqual(d.axis,.vertical)
        XCTAssertNil(d.commit(cameras:[front],microphones:[mic]))
        d.mode=mode;XCTAssertNil(d.commit(cameras:[front],microphones:[mic]))
        d.microphoneID=mic.id;XCTAssertNil(d.commit(cameras:[back],microphones:[mic]))
        let new=try XCTUnwrap(d.commit(cameras:[front],microphones:[mic]))
        XCTAssertEqual(new.axis,.vertical);XCTAssertEqual(new.camera.position,.front)
        XCTAssertEqual(old.axis,.horizontal);XCTAssertEqual(old.camera.position,.back)
    }

    func testClosingEachPreStartPhaseCancelsCallbacksAndDoesNotWriteClaim() throws {
        for phase in [P3Phase.permission,.preparing,.ready] {
            var state=P3State(),epoch=P3PreviewEpoch(),consent=P3PreparationConsent(scope:.cameraSettings)
            consent.acknowledgeInstructions();XCTAssertTrue(state.accept(.prepare));let old=epoch.begin()
            if phase != .permission { XCTAssertTrue(state.accept(.permitted)) }
            if phase == .ready {
                XCTAssertTrue(state.accept(.prepared));consent.observePreview(ready:true)
                XCTAssertTrue(consent.confirmPreview(phase:state.phase,sessionRunning:true,humanVisible:true))
            }
            XCTAssertTrue(state.accept(.pause));epoch.cancel();consent.observePreview(ready:false)
            XCTAssertFalse(epoch.accepts(old));XCTAssertFalse(state.accept(.prepared))
            XCTAssertFalse(consent.confirmPreview(phase:state.phase,sessionRunning:true,humanVisible:true))
            var gate=P3StartClaimGate(),writes=0
            XCTAssertFalse(try gate.reserve(admitted:consent.mayRecord(phase:state.phase,sessionRunning:true)) { writes += 1 })
            XCTAssertEqual(writes,0);XCTAssertFalse(gate.claimed)
            XCTAssertTrue(state.accept(.resume));let fresh=epoch.begin()
            XCTAssertFalse(epoch.accepts(old));XCTAssertTrue(epoch.accepts(fresh))
            XCTAssertFalse(state.accept(.resume));XCTAssertFalse(consent.mayRecord(phase:state.phase,sessionRunning:true))
        }
    }

    func testRepeatedPauseResumeRequiresNewImageAndIgnoresAllPriorEpochs() {
        var state=P3State(),epoch=P3PreviewEpoch(),consent=P3PreparationConsent(scope:.cameraSettings)
        consent.acknowledgeInstructions();XCTAssertTrue(state.accept(.prepare))
        XCTAssertTrue(state.accept(.permitted));XCTAssertTrue(state.accept(.prepared))
        var previous=[epoch.begin()]
        for _ in 0..<16 {
            consent.observePreview(ready:true)
            XCTAssertFalse(consent.mayRecord(phase:state.phase,sessionRunning:true))
            XCTAssertTrue(consent.confirmPreview(phase:state.phase,sessionRunning:true,humanVisible:true))
            XCTAssertTrue(consent.mayRecord(phase:state.phase,sessionRunning:true))
            XCTAssertTrue(state.accept(.pause));epoch.cancel();consent.observePreview(ready:false)
            XCTAssertFalse(state.accept(.record));XCTAssertFalse(state.accept(.prepared))
            XCTAssertTrue(state.accept(.resume));let fresh=epoch.begin()
            XCTAssertTrue(previous.allSatisfy { !epoch.accepts($0) });XCTAssertTrue(epoch.accepts(fresh))
            XCTAssertTrue(state.accept(.permitted));XCTAssertTrue(state.accept(.prepared))
            previous.append(fresh)
        }
        XCTAssertTrue(state.accept(.fail));epoch.cancel();consent.invalidate()
        consent.observePreview(ready:true);consent.acknowledgeInstructions()
        XCTAssertFalse(previous.contains { epoch.accepts($0) });XCTAssertFalse(state.accept(.resume))
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
    }

    func testSelectionControllerMismatchCannotUseOldCameraOrChangedFrameForAdmission() throws {
        var a=draft(front,axis:.vertical)
        let config=try XCTUnwrap(a.commit(cameras:[front],microphones:[mic]))
        let selected=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:config.policy)
        let oldBack=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:.rear)
        let changed=P3OrientationFrame(posture:.portraitUpsideDown,previewAngle:270,captureAngle:270,cameraPolicy:config.policy)
        XCTAssertFalse(config.policy.admits(framePolicy:oldBack.cameraPolicy,captureSupported:true,captureMirrored:false,captureAutomatic:false))
        XCTAssertFalse(config.appliedMatches(cameraID:back.id,mode:mode,minimumDuration:1/30,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(config.mayStart(free:P3Limits.startSpace,inputIDs:["stale-input"],permissions:true,thermalSafe:true))
        var consent=P3PreparationConsent(scope:.cameraSettings);consent.acknowledgeInstructions();consent.observePreview(ready:true)
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertFalse(P3OrientationStartTransaction.admitted(selected,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        consent.observePreview(ready:false);consent.observePreview(ready:true)
        XCTAssertFalse(P3OrientationStartTransaction.admitted(changed,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(P3OrientationStartTransaction.admitted(changed,latest:changed,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertFalse(P3OrientationStartTransaction.admitted(changed,latest:changed,consent:consent,phase:.ready,sessionRunning:false))
    }

    func testEditingAndNewPresentationCannotReplaceExistingClaimOrOriginal() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("camera-settings-synthetic-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let original=root.appendingPathComponent("historical-original.bin"),claim=root.appendingPathComponent("ATTEMPT-RESERVED.json")
        let bytes=Data("synthetic historical original; no device media".utf8),claimBytes=Data("synthetic consumed attempt".utf8)
        try bytes.write(to:original);try claimBytes.write(to:claim,options:.withoutOverwriting)
        let beforeHash=SHA256.hex(try Data(contentsOf:original))
        var d=draft(back,axis:.horizontal)
        _=try XCTUnwrap(d.commit(cameras:[back],microphones:[mic]));d.returnToEditing()
        d.chooseCamera(front.id);d.mode=mode;d.axis = .vertical
        let next=P4SettingsPreparation(configuration:try XCTUnwrap(d.commit(cameras:[front],microphones:[mic])))
        XCTAssertEqual(next.configuration.axis,.vertical)
        var gate=P3StartClaimGate()
        XCTAssertThrowsError(try gate.reserve(admitted:true) { try Data("replacement".utf8).write(to:claim,options:.withoutOverwriting) })
        XCTAssertEqual(try Data(contentsOf:claim),claimBytes);XCTAssertEqual(SHA256.hex(try Data(contentsOf:original)),beforeHash)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath:root.path)),Set(["historical-original.bin","ATTEMPT-RESERVED.json"]))
        XCTAssertFalse(gate.claimed)
    }
}
