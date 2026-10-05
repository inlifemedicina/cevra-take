import XCTest
@testable import PersistenceProof

final class P4SyncReferenceTests: XCTestCase {
    private func events(_ offsets: [Double], uncertainty: Double = 0.002) -> [P4SyncObservation] {
        zip(zip([P4SyncMark.start, .middle, .end], [2.0, 15.0, 27.0]), offsets).map {
            P4SyncObservation(mark: $0.0.0, videoSeconds: $0.0.1, audioSeconds: $0.0.1 + $0.1, uncertaintySeconds: uncertainty)
        }
    }
    private func measure(_ observations: [P4SyncObservation]) throws -> P4SyncMeasurement {
        try P4SyncReference.measure(observations, durationSeconds: 30,
            maximumAbsoluteOffsetSeconds: 0.080, maximumDriftSeconds: 0.040)
    }
    func testOffsetsAndSignedDriftWithKnownSyntheticReferences() throws {
        let result = try measure(events([0.025, 0.035, 0.045]))
        XCTAssertEqual(result.status, .pass)
        XCTAssertEqual(result.maximumAbsoluteOffsetSeconds, 0.045, accuracy: 1e-12)
        XCTAssertEqual(result.offsetRangeSeconds, 0.020, accuracy: 1e-12)
        XCTAssertEqual(result.firstToLastDriftSeconds, 0.020, accuracy: 1e-12)
        XCTAssertEqual(result.absoluteOffsetUpperBoundSeconds, 0.047, accuracy: 1e-12)
        XCTAssertEqual(result.driftUpperBoundSeconds, 0.024, accuracy: 1e-12)
        let negative = try measure(events([-0.045, -0.035, -0.025]))
        XCTAssertEqual(negative.status, .pass)
        XCTAssertEqual(negative.firstToLastDriftSeconds, 0.020, accuracy: 1e-12)
    }
    func testConstantOffsetAndMiddleExcursionFailIndependently() throws {
        XCTAssertEqual(try measure(events([0.1, 0.1, 0.1])).status, .fail)
        // Start/end agreement must not hide a large middle drift.
        XCTAssertEqual(try measure(events([0, 0.07, 0])).status, .fail)
        XCTAssertEqual(try measure(events([-0.07, 0, 0.07])).status, .fail)
    }
    func testUncertaintyCrossingThresholdCannotPass() throws {
        XCTAssertEqual(try measure(events([0.079, 0.079, 0.079])).status, .notVerifiable)
        XCTAssertEqual(try measure(events([0, 0.039, 0])).status, .notVerifiable)
        XCTAssertEqual(try measure(events([0, 0, 0], uncertainty: 0.030)).status, .notVerifiable)
    }
    func testMissingDuplicateOutOfOrderAndWrongWindowReferencesRejected() throws {
        let good = events([0, 0, 0])
        for bad in [Array(good.prefix(2)), [good[0], good[0], good[2]], [good[2], good[1], good[0]],
                    [P4SyncObservation(mark: .start, videoSeconds: 10, audioSeconds: 10, uncertaintySeconds: 0), good[1], good[2]]] {
            XCTAssertThrowsError(try measure(bad))
        }
    }
    func testNonfiniteNegativeOutOfClipAndUnboundedArithmeticRejected() throws {
        let good = events([0, 0, 0])
        for bad in [
            P4SyncObservation(mark: .start, videoSeconds: .nan, audioSeconds: 2, uncertaintySeconds: 0),
            P4SyncObservation(mark: .start, videoSeconds: 2, audioSeconds: .infinity, uncertaintySeconds: 0),
            P4SyncObservation(mark: .start, videoSeconds: 2, audioSeconds: -1, uncertaintySeconds: 0),
            P4SyncObservation(mark: .start, videoSeconds: 2, audioSeconds: 31, uncertaintySeconds: 0),
            P4SyncObservation(mark: .start, videoSeconds: 2, audioSeconds: 2, uncertaintySeconds: -0.1)] {
            XCTAssertThrowsError(try measure([bad, good[1], good[2]]))
        }
        for duration in [Double.nan, .infinity, -1, 10] {
            XCTAssertThrowsError(try P4SyncReference.measure(good, durationSeconds: duration, maximumAbsoluteOffsetSeconds: 0.08, maximumDriftSeconds: 0.04))
        }
        for limit in [Double.nan, .infinity, -1, 0] {
            XCTAssertThrowsError(try P4SyncReference.measure(good, durationSeconds: 30, maximumAbsoluteOffsetSeconds: limit, maximumDriftSeconds: 0.04))
            XCTAssertThrowsError(try P4SyncReference.measure(good, durationSeconds: 30, maximumAbsoluteOffsetSeconds: 0.08, maximumDriftSeconds: limit))
        }
    }
}
