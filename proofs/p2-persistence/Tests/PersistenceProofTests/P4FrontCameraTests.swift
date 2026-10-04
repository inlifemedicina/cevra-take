import XCTest
@testable import PersistenceProof

final class P4FrontCameraTests:XCTestCase {
    func testFrontalNamespaceIsOnlyNewCaptureAndRetainsManualBindingScope() {
        let front=P3AttemptScope.manualTextFrontVertical
        XCTAssertTrue(front.allowsCapture);XCTAssertTrue(front.hasManualText)
        XCTAssertEqual(front.axis,.vertical);XCTAssertEqual(front.cameraPolicy.position,.front)
        XCTAssertEqual(front.base(in:URL(fileURLWithPath:"/synthetic/P3CaptureSandbox")).lastPathComponent,"P4-MANUAL-TEXT-FRONT-VERTICAL-001")
        let rear=P3AttemptScope.manualTextVertical
        XCTAssertFalse(rear.allowsCapture);XCTAssertTrue(rear.hasManualText)
        XCTAssertEqual(rear.cameraPolicy.position,.back)
        XCTAssertNotEqual(rear.base(in:URL(fileURLWithPath:"/synthetic")),front.base(in:URL(fileURLWithPath:"/synthetic")))
    }
    func testPreviewAndOriginalMirroringAreSeparateAndFailClosed() {
        let policy=P4CameraPolicy.frontProof
        XCTAssertTrue(policy.previewReady(supported:true,mirrored:true,automatic:false))
        XCTAssertFalse(policy.previewReady(supported:false,mirrored:true,automatic:false))
        XCTAssertFalse(policy.previewReady(supported:true,mirrored:false,automatic:false))
        XCTAssertFalse(policy.previewReady(supported:true,mirrored:true,automatic:true))
        XCTAssertTrue(policy.admits(framePolicy:policy,captureSupported:true,captureMirrored:false,captureAutomatic:false))
        XCTAssertFalse(policy.admits(framePolicy:policy,captureSupported:false,captureMirrored:false,captureAutomatic:false))
        XCTAssertFalse(policy.admits(framePolicy:policy,captureSupported:true,captureMirrored:true,captureAutomatic:false))
        XCTAssertFalse(policy.admits(framePolicy:policy,captureSupported:true,captureMirrored:false,captureAutomatic:true))
        XCTAssertFalse(policy.admits(framePolicy:.rear,captureSupported:true,captureMirrored:false,captureAutomatic:false))
    }
    func testMirrorCameraChangeInvalidatesSameAngleAdmissionWithoutClaim() {
        var consent=P3PreparationConsent(scope:.manualTextFrontVertical)
        consent.acknowledgeInstructions();consent.observePreview(ready:true)
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        let proposed=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:.frontProof)
        let wrongCamera=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:.rear)
        let wrongMirror=P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90,cameraPolicy:P4CameraPolicy(position:.front,previewMirrored:false,originalMirrored:false))
        XCTAssertFalse(P3OrientationStartTransaction.admitted(proposed,latest:wrongCamera,consent:consent,phase:.ready,sessionRunning:true))
        XCTAssertFalse(P3OrientationStartTransaction.admitted(proposed,latest:wrongMirror,consent:consent,phase:.ready,sessionRunning:true))
        var claim=P3StartClaimGate();var writes=0
        XCTAssertFalse(try claim.reserve(admitted:P3OrientationStartTransaction.admitted(proposed,latest:wrongMirror,consent:consent,phase:.ready,sessionRunning:true),exclusiveWrite:{ writes += 1 }))
        XCTAssertEqual(writes,0);XCTAssertFalse(claim.claimed)
        XCTAssertTrue(P3OrientationStartTransaction.admitted(proposed,latest:proposed,consent:consent,phase:.ready,sessionRunning:true))
        consent.observePreview(ready:false)
        XCTAssertFalse(P3OrientationStartTransaction.admitted(proposed,latest:proposed,consent:consent,phase:.ready,sessionRunning:true))
    }
    func testFrontalFreezeRequiresVerticalSupportedAnglesAndKeepsMirrorPolicy() {
        let front=P3OrientationFrame(posture:.portrait,previewAngle:270,captureAngle:90,cameraPolicy:.frontProof)
        var freeze=P3OrientationFreeze()
        XCTAssertFalse(freeze.lock(front,axis:.horizontal,previewSupported:true,captureSupported:true))
        XCTAssertFalse(freeze.lock(front,axis:.vertical,previewSupported:true,captureSupported:false))
        XCTAssertTrue(freeze.lock(front,axis:.vertical,previewSupported:true,captureSupported:true))
        XCTAssertEqual(freeze.frame?.cameraPolicy,.frontProof)
        XCTAssertFalse(freeze.lock(P3OrientationFrame(posture:.portrait,previewAngle:90,captureAngle:90),axis:.vertical,previewSupported:true,captureSupported:true))
        var start=P3OrientationStartTransaction();XCTAssertTrue(start.propose(front,axis:.vertical,previewSupported:true))
        XCTAssertTrue(start.finish(accepted:false));XCTAssertNil(start.frame)
        XCTAssertTrue(start.propose(front,axis:.vertical,previewSupported:true));XCTAssertTrue(start.finish(accepted:true))
        XCTAssertEqual(start.committed?.cameraPolicy,.frontProof)
    }
}
