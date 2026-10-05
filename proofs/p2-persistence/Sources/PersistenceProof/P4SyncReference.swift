import Foundation

// Arithmetic over future decoded/annotated reference events, never track presence,
// cadence, nominal FPS or human "looks correct". No media/device access or defaults.
public enum P4SyncMark: String, Sendable { case start, middle, end }
public struct P4SyncObservation: Sendable {
    public let mark: P4SyncMark
    public let videoSeconds: Double
    public let audioSeconds: Double
    public let uncertaintySeconds: Double
    public init(mark: P4SyncMark, videoSeconds: Double, audioSeconds: Double, uncertaintySeconds: Double) {
        self.mark = mark; self.videoSeconds = videoSeconds
        self.audioSeconds = audioSeconds; self.uncertaintySeconds = uncertaintySeconds
    }
}
public enum P4SyncStatus: String, Sendable { case pass, fail, notVerifiable }
public struct P4SyncMeasurement: Sendable {
    public let status: P4SyncStatus
    public let offsetsSeconds: [Double]
    public let maximumAbsoluteOffsetSeconds: Double
    public let offsetRangeSeconds: Double
    public let firstToLastDriftSeconds: Double
    public let absoluteOffsetUpperBoundSeconds: Double
    public let driftUpperBoundSeconds: Double
}
public enum P4SyncError: Error { case invalidLimits, invalidReference }
public enum P4SyncReference {
    // Caller must preregister these limits for the future experiment before measuring.
    // Uncertainty that crosses a threshold returns notVerifiable, never a guessed PASS.
    public static func measure(_ observations: [P4SyncObservation], durationSeconds: Double,
                               maximumAbsoluteOffsetSeconds: Double,
                               maximumDriftSeconds: Double) throws -> P4SyncMeasurement {
        guard maximumAbsoluteOffsetSeconds.isFinite, maximumAbsoluteOffsetSeconds > 0,
              maximumDriftSeconds.isFinite, maximumDriftSeconds > 0 else { throw P4SyncError.invalidLimits }
        guard durationSeconds.isFinite, (29...31).contains(durationSeconds),
              observations.map(\.mark) == [.start, .middle, .end],
              observations.allSatisfy({ o in
                  o.videoSeconds.isFinite && o.audioSeconds.isFinite && o.uncertaintySeconds.isFinite &&
                  o.videoSeconds >= 0 && o.videoSeconds <= durationSeconds &&
                  o.audioSeconds >= 0 && o.audioSeconds <= durationSeconds && o.uncertaintySeconds >= 0
              }) else { throw P4SyncError.invalidReference }
        let windows = [0.0...0.15, 0.45...0.55, 0.85...1.0]
        guard zip(observations, windows).allSatisfy({ $1.contains($0.videoSeconds / durationSeconds) }),
              observations[0].audioSeconds < observations[1].audioSeconds,
              observations[1].audioSeconds < observations[2].audioSeconds else { throw P4SyncError.invalidReference }
        let offsets = observations.map { $0.audioSeconds - $0.videoSeconds }
        let uncertainties = observations.map(\.uncertaintySeconds)
        let lower = zip(offsets, uncertainties).map { $0 - $1 }
        let upper = zip(offsets, uncertainties).map { $0 + $1 }
        guard (offsets + lower + upper).allSatisfy(\.isFinite) else { throw P4SyncError.invalidReference }
        let maximum = offsets.map(abs).max()!
        let absoluteUpper = zip(offsets, uncertainties).map { abs($0) + $1 }.max()!
        let absoluteLower = zip(offsets, uncertainties).map { max(0, abs($0) - $1) }.max()!
        let driftUpper = upper.max()! - lower.min()!
        let driftLower = max(0, lower.max()! - upper.min()!)
        guard absoluteUpper.isFinite, driftUpper.isFinite else { throw P4SyncError.invalidReference }
        let status: P4SyncStatus
        if absoluteLower > maximumAbsoluteOffsetSeconds || driftLower > maximumDriftSeconds { status = .fail }
        else if absoluteUpper <= maximumAbsoluteOffsetSeconds && driftUpper <= maximumDriftSeconds { status = .pass }
        else { status = .notVerifiable }
        return P4SyncMeasurement(status: status, offsetsSeconds: offsets,
            maximumAbsoluteOffsetSeconds: maximum,
            offsetRangeSeconds: offsets.max()! - offsets.min()!,
            firstToLastDriftSeconds: offsets[2] - offsets[0],
            absoluteOffsetUpperBoundSeconds: absoluteUpper, driftUpperBoundSeconds: driftUpper)
    }
}
