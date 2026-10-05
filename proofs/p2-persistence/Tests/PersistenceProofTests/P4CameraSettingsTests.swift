import XCTest
@testable import PersistenceProof

final class P4CameraSettingsTests:XCTestCase {
    private let hd=P4VideoMode(width:1920,height:1080,fps:30)
    private let fourK=P4VideoMode(width:3840,height:2160,fps:24)
    private let mic=P4MicrophoneCapability(id:"fixture-mic",name:"Synthetic mic",kind:"MicrophoneBuiltIn")
    private var front:P4CameraCapability { P4CameraCapability(id:"fixture-front",position:.front,modes:[hd,fourK]) }
    private var back:P4CameraCapability { P4CameraCapability(id:"fixture-back",position:.back,modes:[hd]) }
    private func config()->P4CaptureConfiguration {
        P4CaptureConfiguration(camera:front,mode:hd,axis:.horizontal,previewMirrored:true,originalMirrored:false,microphone:mic)
    }
    func testNativeRangesFilterPairsAndDoNotInventHDRorUnsupportedRates() {
        let modes=P4VideoMode.supported(width:1920,height:1080,ranges:[24...30,50...60],sdr:true)
        XCTAssertEqual(modes.map(\.fps),[24,25,30,50,60])
        XCTAssertEqual(P4VideoMode.supported(width:3840,height:2160,ranges:[24...25],sdr:true).map(\.fps),[24,25])
        XCTAssertTrue(P4VideoMode.supported(width:1920,height:1080,ranges:[1...60],sdr:false).isEmpty)
        XCTAssertTrue(P4VideoMode.supported(width:640,height:480,ranges:[1...60],sdr:true).isEmpty)
        XCTAssertTrue(P4VideoMode.supported(width:1920,height:1080,ranges:[120...240],sdr:true).isEmpty)
    }
    func testNoAutomaticFallbackForMissingCameraModeOrMicrophone() {
        var draft=P4SettingsDraft();draft.cameraID=front.id;draft.mode=fourK;draft.microphoneID=mic.id
        XCTAssertNil(draft.commit(cameras:[back],microphones:[mic]))
        draft.cameraID=back.id
        XCTAssertNil(draft.commit(cameras:[back],microphones:[mic]))
        draft.mode=hd
        XCTAssertNil(draft.commit(cameras:[back],microphones:[]))
        XCTAssertNil(draft.committed)
    }
    func testCameraChangeClearsIncompatibleModeAndCommitFreezesAllChoices() {
        var draft=P4SettingsDraft();draft.chooseCamera(front.id);draft.mode=fourK;draft.microphoneID=mic.id
        draft.chooseCamera(back.id);XCTAssertNil(draft.mode)
        draft.mode=hd;draft.axis = .horizontal;draft.previewMirrored=false;draft.originalMirrored=true
        let committed=draft.commit(cameras:[front,back],microphones:[mic])
        XCTAssertEqual(committed?.axis,.horizontal);XCTAssertEqual(committed?.policy.position,.back)
        XCTAssertEqual(committed?.policy.originalMirrored,true);XCTAssertFalse(draft.editable)
        draft.chooseCamera(front.id);XCTAssertEqual(draft.cameraID,back.id)
        XCTAssertNil(draft.commit(cameras:[front,back],microphones:[mic]))
        draft.returnToEditing();draft.chooseCamera(front.id)
        XCTAssertTrue(draft.editable);XCTAssertEqual(committed?.camera.position,.back)
    }
    func testAppliedChecksRejectDeviceRouteAndFrameDurationDrift() {
        let c=config()
        XCTAssertTrue(c.appliedMatches(cameraID:front.id,mode:hd,minimumDuration:1/30,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(c.appliedMatches(cameraID:back.id,mode:hd,minimumDuration:1/30,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(c.appliedMatches(cameraID:front.id,mode:hd,minimumDuration:1/24,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(c.appliedMatches(cameraID:front.id,mode:hd,minimumDuration:.nan,maximumDuration:1/30,inputIDs:[mic.id]))
        XCTAssertFalse(c.appliedMatches(cameraID:front.id,mode:hd,minimumDuration:1/30,maximumDuration:1/30,inputIDs:["other-mic"]))
        XCTAssertFalse(c.routeMatches(ids:[mic.id,"second-input"]))
    }
    func testSelectedExternalRouteNeedsAllStartGuardsWithoutChangingOldInternalRule() {
        let external=P4MicrophoneCapability(id:"fixture-usb",name:"Synthetic USB",kind:"USBAudio")
        let c=P4CaptureConfiguration(camera:front,mode:hd,axis:.vertical,previewMirrored:false,originalMirrored:false,microphone:external)
        XCTAssertTrue(c.mayStart(free:P3Limits.startSpace,inputIDs:[external.id],permissions:true,thermalSafe:true))
        XCTAssertFalse(c.mayStart(free:P3Limits.startSpace-1,inputIDs:[external.id],permissions:true,thermalSafe:true))
        XCTAssertFalse(c.mayStart(free:nil,inputIDs:[external.id],permissions:true,thermalSafe:true))
        XCTAssertFalse(c.mayStart(free:P3Limits.startSpace,inputIDs:[external.id],permissions:false,thermalSafe:true))
        XCTAssertFalse(c.mayStart(free:P3Limits.startSpace,inputIDs:[external.id],permissions:true,thermalSafe:false))
        XCTAssertFalse(c.mayStart(free:P3Limits.startSpace,inputIDs:[mic.id],permissions:true,thermalSafe:true))
        XCTAssertFalse(P3Limits.mayStart(free:P3Limits.startSpace,internalMic:false,permissions:true,thermalSafe:true))
    }
    func testConfiguredProfileNeverPromotesOldFixedProfileOrChangesTolerance() {
        XCTAssertTrue(fourK.fileProfile(duration:30,width:2160,height:3840,fps:24,videoTracks:1,audioTracks:1,sdr:true))
        XCTAssertFalse(P3Limits.fileProfile(duration:30,width:2160,height:3840,fps:24,videoTracks:1,audioTracks:1,sdrVerified:true))
        XCTAssertFalse(hd.fileProfile(duration:30,width:1920,height:1080,fps:30.02,videoTracks:1,audioTracks:1,sdr:true))
        XCTAssertFalse(hd.fileProfile(duration:28,width:1920,height:1080,fps:30,videoTracks:1,audioTracks:1,sdr:true))
        XCTAssertFalse(hd.fileProfile(duration:30,width:1920,height:1080,fps:30,videoTracks:1,audioTracks:0,sdr:true))
    }
    func testStoredTargetAndFailureAreReadOnlyAndIndependentOfNewDraft() {
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:123)
        var report=config().report;report.merge(["attempt":P3AttemptScope.cameraSettings.rawValue,"profile":"FAIL","nominalFPS":"30.02","sha256":original.sha256,"bytes":"123"]) { _,v in v }
        let result=P3FileFeedback.recorded(report,matching:original)
        XCTAssertEqual(result.configuredFPS,30);XCTAssertEqual(result.profile,.fail);XCTAssertNil(result.independentlyMeasuredAverageFPS)
        XCTAssertTrue(result.targetText(.en).contains("30 fps"))
        XCTAssertFalse(report.values.contains(front.id));XCTAssertFalse(report.values.contains(mic.id));XCTAssertFalse(report.values.contains(mic.name))
        report["configuredFPS"]="24"
        XCTAssertEqual(result.configuredFPS,30)
        var old=report;old["attempt"]=P3AttemptScope.manualTextFrontVertical.rawValue
        XCTAssertEqual(P3FileFeedback.recorded(old,matching:original).configuredFPS,30)
    }
    func testConfigurationAvailabilityRejectsStaleDeviceAndDisconnectedInput() {
        let c=config();XCTAssertTrue(c.isAvailable(cameras:[front],microphones:[mic]))
        XCTAssertFalse(c.isAvailable(cameras:[back],microphones:[mic]))
        XCTAssertFalse(c.isAvailable(cameras:[front],microphones:[]))
        var epoch=P3PreviewEpoch();let token=epoch.begin();epoch.cancel();XCTAssertFalse(epoch.accepts(token))
        let next=epoch.begin();XCTAssertTrue(epoch.accepts(next))
    }
    func testHorizontalAndMirroringChoiceRetainsExistingHumanAdmission() {
        let c=config();var consent=P3PreparationConsent(scope:.cameraSettings)
        XCTAssertFalse(consent.mayPrepare(phase:.idle));consent.acknowledgeInstructions()
        consent.observePreview(ready:true);XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        let f=P3OrientationFrame(posture:.landscapePortLeft,previewAngle:0,captureAngle:0,cameraPolicy:c.policy)
        var freeze=P3OrientationFreeze()
        XCTAssertFalse(freeze.lock(f,axis:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertTrue(freeze.lock(f,axis:c.axis,previewSupported:true,captureSupported:true))
        XCTAssertTrue(P3OrientationStartTransaction.admitted(f,latest:f,consent:consent,phase:.ready,sessionRunning:true))
        consent.observePreview(ready:false)
        XCTAssertFalse(P3OrientationStartTransaction.admitted(f,latest:f,consent:consent,phase:.ready,sessionRunning:true))
    }
    func testMissingSettingsReportDoesNotInventConfiguredThirtyFPS() {
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:123)
        XCTAssertNil(P3FileFeedback.recorded(nil,matching:original,requiresSettingsReport:true).configuredFPS)
        let wrong=["sha256":original.sha256,"bytes":"123","profile":"PASS","attempt":P3AttemptScope.original.rawValue]
        let result=P3FileFeedback.recorded(wrong,matching:original,requiresSettingsReport:true)
        XCTAssertEqual(result.profile,.unavailable);XCTAssertNil(result.configuredFPS)
    }
    func testRecordedChoicesAreWhitelistedAndMismatchNeverLooksApplied() {
        let report=config().report
        let stored=P4RecordedSettings(report:report)
        XCTAssertEqual(stored?.mode,hd);XCTAssertEqual(stored?.axis,.horizontal)
        XCTAssertEqual(stored?.policy.previewMirrored,true);XCTAssertEqual(stored?.policy.originalMirrored,false)
        XCTAssertTrue(stored?.text(.pt).contains("somente leitura") == true)
        var mismatched=report;mismatched["appliedFPS"]="24";XCTAssertNil(P4RecordedSettings(report:mismatched))
        var untrusted=report;untrusted["configuredInputKind"]="private/name/path";XCTAssertNil(P4RecordedSettings(report:untrusted))
        var changed=report;changed["configuredOrientation"]="vertical"
        XCTAssertEqual(stored?.axis,.horizontal)
        XCTAssertEqual(P4RecordedSettings(report:changed)?.axis,.vertical)
    }
    func testHorizontalToVerticalPreparationUsesNewIdentityAndImmutableChoice() throws {
        var draft=P4SettingsDraft();draft.chooseCamera(back.id);draft.mode=hd;draft.microphoneID=mic.id;draft.axis = .horizontal
        let b=P4SettingsPreparation(configuration:try XCTUnwrap(draft.commit(cameras:[back,front],microphones:[mic])))
        draft.returnToEditing();draft.chooseCamera(front.id);draft.mode=hd;draft.axis = .vertical
        let a=P4SettingsPreparation(configuration:try XCTUnwrap(draft.commit(cameras:[back,front],microphones:[mic])))
        XCTAssertNotEqual(a.id,b.id)
        XCTAssertEqual(b.configuration.axis,.horizontal);XCTAssertEqual(b.configuration.camera.position,.back)
        XCTAssertEqual(a.configuration.axis,.vertical);XCTAssertEqual(a.configuration.camera.position,.front)
        XCTAssertEqual(a.configuration.positionText(.pt),"Posição deste preparo: Vertical")
        XCTAssertEqual(b.configuration.positionText(.en),"Position for this preparation: Landscape")
        draft.returnToEditing();draft.axis = .horizontal
        XCTAssertEqual(a.configuration.axis,.vertical)
        let next=P4SettingsPreparation(configuration:a.configuration)
        XCTAssertNotEqual(next.id,a.id)
        let copy=a;XCTAssertEqual(copy.id,a.id)
    }
    func testCameraChangeDoesNotSilentlyChooseAnOrientation() throws {
        var draft=P4SettingsDraft();draft.axis = .horizontal;draft.chooseCamera(back.id);draft.mode=hd;draft.microphoneID=mic.id
        _=try XCTUnwrap(draft.commit(cameras:[back,front],microphones:[mic]))
        draft.returnToEditing();draft.chooseCamera(front.id)
        XCTAssertNil(draft.mode);XCTAssertEqual(draft.axis,.horizontal)
        XCTAssertEqual(draft.axis.choiceText(.pt),"Horizontal")
        draft.mode=hd
        let snapshot=P4SettingsPreparation(configuration:try XCTUnwrap(draft.commit(cameras:[front],microphones:[mic])))
        XCTAssertEqual(snapshot.configuration.positionText(.pt),"Posição deste preparo: Horizontal")
    }
    func testPortraitInHorizontalPreparationCannotConfirmOrConsumeClaim() throws {
        let c=config();let frame=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:c.policy)
        var consent=P3PreparationConsent(scope:.cameraSettings);consent.acknowledgeInstructions()
        let supported=frame.supported(for:c.axis,previewSupported:true,captureSupported:true)
        XCTAssertFalse(supported);consent.observePreview(ready:supported)
        XCTAssertFalse(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        var claim=P3StartClaimGate();var writes=0
        XCTAssertFalse(try claim.reserve(admitted:consent.mayRecord(phase:.ready,sessionRunning:true),exclusiveWrite:{writes += 1}))
        XCTAssertEqual(writes,0);XCTAssertFalse(claim.claimed)
    }
}
