import XCTest
@testable import PersistenceProof

final class P3FeedbackTests:XCTestCase {
    private let original=Original(id:"fixture",sha256:String(repeating:"a",count:64),byteCount:123)
    private func report(profile:String="FAIL",fps:String="30.02")->[String:String] {
        ["sha256":original.sha256,"bytes":"123","profile":profile,"nominalFPS":fps]
    }
    func testHorizontalOrUnknownCannotPresentConfirmationAsReady() {
        for posture in [P3Posture.landscapePortLeft,.landscapePortRight,.unknown] {
            let status=P3PreparationFeedback(phase:.ready,axis:.vertical,posture:posture,signalReady:true,confirmed:true,allowsCapture:true)
            XCTAssertTrue(status.text(.pt).contains("bloqueada"))
            XCTAssertTrue(status.text(.en).contains("blocked"))
            XCTAssertTrue(status.text(.pt).contains("prévia pode continuar"))
        }
        let missing=P3PreparationFeedback(phase:.ready,axis:.vertical,posture:nil,signalReady:true,confirmed:true,allowsCapture:true)
        XCTAssertTrue(missing.text(.en).contains("blocked"))
    }
    func testReturningVerticalStillNeedsNewConfirmationAndReadyPreview() {
        let needsConfirmation=P3PreparationFeedback(phase:.ready,axis:.vertical,posture:.portrait,signalReady:true,confirmed:false,allowsCapture:true)
        XCTAssertTrue(needsConfirmation.text(.pt).contains("pendente"))
        let notReady=P3PreparationFeedback(phase:.ready,axis:.vertical,posture:.portrait,signalReady:false,confirmed:true,allowsCapture:true)
        XCTAssertTrue(notReady.text(.en).contains("blocked"))
        let confirmed=P3PreparationFeedback(phase:.ready,axis:.vertical,posture:.portrait,signalReady:true,confirmed:true,allowsCapture:true)
        XCTAssertTrue(confirmed.text(.pt).contains("somente pelo botão"))
    }
    func testPhaseWinsOverStalePreviewFlagsAndHistoryCannotPrepare() {
        let paused=P3PreparationFeedback(phase:.paused,axis:.vertical,posture:.portrait,signalReady:true,confirmed:true,allowsCapture:true)
        XCTAssertTrue(paused.text(.pt).contains("nova imagem"))
        let recording=P3PreparationFeedback(phase:.recording,axis:.vertical,posture:.landscapePortLeft,signalReady:false,confirmed:false,allowsCapture:true)
        XCTAssertTrue(recording.text(.pt).hasPrefix("Gravando"))
        let historical=P3PreparationFeedback(phase:.idle,axis:.vertical,posture:nil,signalReady:false,confirmed:false,allowsCapture:false)
        XCTAssertTrue(historical.text(.en).contains("Reopen and Play only"))
    }
    func testRecordedFailureSurvivesVerifiedReopenEvenWhenFPSMatchesTarget() {
        let feedback=P3FileFeedback.recorded(report(fps:"30"),matching:original)
        XCTAssertEqual(feedback.integrity,.verified);XCTAssertEqual(feedback.profile,.fail)
        XCTAssertTrue(feedback.profileText(.pt).contains("FAIL"))
        XCTAssertTrue(feedback.profileText(.en).contains("does not change"))
        XCTAssertNil(feedback.independentlyMeasuredAverageFPS)
        XCTAssertTrue(feedback.playbackText(.en).contains("do not record human acceptance"))
    }
    func testMissingMismatchedOrUnknownReportCannotApproveProfile() {
        var changed=report();changed["sha256"]=String(repeating:"b",count:64)
        var wrongSize=report();wrongSize["bytes"]="124"
        for raw in [nil,changed,wrongSize,report(profile:"unknown")] {
            let feedback=P3FileFeedback.recorded(raw,matching:original)
            XCTAssertEqual(feedback.integrity,.verified)
            XCTAssertEqual(feedback.profile,.unavailable)
        }
    }
    func testNonFiniteInvalidFPSNeverBecomesAMeasuredAverage() {
        for value in ["nan","inf","-1","invalid"] {
            let feedback=P3FileFeedback.recorded(report(fps:value),matching:original)
            XCTAssertNil(feedback.reportedFPS);XCTAssertNil(feedback.independentlyMeasuredAverageFPS)
            XCTAssertEqual(feedback.profile,.fail)
            XCTAssertTrue(feedback.averageFPSText(.pt).contains("não medido"))
        }
    }
    func testTargetReportedAndIndependentlyMeasuredFPSRemainSeparate() {
        let feedback=P3FileFeedback(integrity:.verified,profile:.fail,reportedFPS:30.02,independentlyMeasuredAverageFPS:24)
        XCTAssertTrue(feedback.targetText(.en).contains("30 fps"))
        XCTAssertTrue(feedback.reportedFPSText(.en).contains("30.020000"))
        XCTAssertTrue(feedback.averageFPSText(.en).contains("24.000000"))
        XCTAssertFalse(P3Limits.fileProfile(duration:30,width:1920,height:1080,fps:30.02,videoTracks:1,audioTracks:1,sdrVerified:true))
        XCTAssertEqual(feedback.profile,.fail)
        XCTAssertEqual(P3FeedbackLanguage(localeIdentifier:"en-US"),.en)
        XCTAssertEqual(P3FeedbackLanguage(localeIdentifier:"pt-BR"),.pt)
    }
}
