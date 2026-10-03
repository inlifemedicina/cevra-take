import Foundation

// Pure protocol gates: importing/constructing this type never accesses media hardware.
public enum P3Phase: String, Sendable { case idle, permission, preparing, ready, starting, recording, finalizing, saved, failed }
public enum P3Event: Sendable { case prepare, permitted, prepared, record, started, stop, finished, persisted, recovered, fail }
public struct P3State: Sendable {
    public private(set) var phase: P3Phase = .idle
    public init() {}
    @discardableResult public mutating func accept(_ event: P3Event) -> Bool {
        if case .fail = event { phase = .failed; return true }
        let next: P3Phase?
        switch (phase, event) {
        case (.idle,.prepare): next = .permission
        case (.permission,.permitted): next = .preparing
        case (.preparing,.prepared): next = .ready
        case (.ready,.record): next = .starting
        case (.starting,.started): next = .recording
        case (.starting,.stop),(.recording,.stop): next = .finalizing
        case (.recording,.finished),(.starting,.finished),(.finalizing,.finished): next = .finalizing
        case (.finalizing,.persisted),(.idle,.recovered): next = .saved
        default: next = nil
        }
        guard let next else { return false }; phase = next; return true
    }
}
public enum P3Limits {
    public static let seconds = 30.0
    public static let reserve: Int64 = 1_073_741_824
    // 12 Mbit/s * 30 s / 8, with 3 copies/headroom before starting; not a measured size.
    public static let startSpace: Int64 = reserve + 135_000_000
    public static func mayStart(free: Int64?, internalMic: Bool, permissions: Bool, thermalSafe: Bool) -> Bool {
        guard let free else { return false }
        return free >= startSpace && internalMic && permissions && thermalSafe
    }
    public static func fileProfile(duration: Double, width: Int, height: Int, fps: Double,
                                   videoTracks: Int, audioTracks: Int, sdrVerified: Bool) -> Bool {
        duration.isFinite && (29.0...31.0).contains(duration) &&
        ((width == 1920 && height == 1080) || (width == 1080 && height == 1920)) &&
        fps.isFinite && abs(fps - 30.0) <= 0.001 && videoTracks == 1 && audioTracks >= 1 && sdrVerified
    }
    public static func snapshot(_ original: Original) -> Snapshot {
        Snapshot(formatVersion: 1, projectID: "P3-CAPTURE-001",
                 revisions: [Revision(id: "R1", scriptID: "S", text: "Prova P3 autorizada: objeto neutro e contagem em voz alta.")],
                 takes: [Take(id: "T", revisionID: "R1", originalID: "O", synthetic: false)], originals: [original])
    }
}

// Deadline eligibility survives stop-before-start, independently of UI phase.
// Once invalidated, no late recording callback can authorize persistence/success.
public struct P3RecordingDeadline: Sendable {
    private var issued=false
    private var started=false
    private var stopped=false
    public private(set) var finished=false
    public private(set) var invalidated=false
    public init() {}
    public mutating func begin() -> Bool {
        guard !issued,!invalidated else { return false };issued=true;return true
    }
    public mutating func startCallback() -> Bool {
        guard issued,!started,!stopped,!finished,!invalidated else { return false }
        started=true;return true
    }
    public mutating func requestStop() -> Bool {
        guard issued,!stopped,!finished,!invalidated else { return false };stopped=true;return true
    }
    public mutating func finishCallback() -> Bool {
        guard issued,!finished,!invalidated else { return false };finished=true;return true
    }
    public mutating func startExpired() -> Bool {
        guard issued,!started,!finished,!invalidated else { return false };invalidated=true;return true
    }
    public mutating func finishExpired() -> Bool {
        guard issued,stopped,!finished,!invalidated else { return false };invalidated=true;return true
    }
    public mutating func completionExpired() -> Bool {
        guard issued,!finished,!invalidated else { return false };invalidated=true;return true
    }
    public mutating func cancel() { invalidated=true }
}


// Fixed protocol namespaces, not a user-provided ID or an automatic retry counter.
public enum P3AttemptScope:String, Sendable {
    case original="P3-ORIGINAL", retry001="P3-RETRY-001", retry002="P3-RETRY-002"
    public var requiresInstructions:Bool { self == .retry002 }
    public var requiresPreview:Bool { self != .original }
    public func base(in root:URL)->URL {
        self == .original ? root : root.appendingPathComponent(rawValue,isDirectory:true)
    }
}
public struct P3PreparationConsent:Sendable {
    public let scope:P3AttemptScope
    public private(set) var instructionsAcknowledged=false
    public private(set) var previewConfirmed=false
    private var previewSignal=false
    private var invalidated=false
    public init(scope:P3AttemptScope) { self.scope=scope }
    public mutating func acknowledgeInstructions() { if !invalidated { instructionsAcknowledged=true } }
    public func mayPrepare(phase:P3Phase)->Bool {
        !invalidated && phase == .idle && (!scope.requiresInstructions || instructionsAcknowledged)
    }
    public mutating func observePreview(ready:Bool) {
        previewSignal=ready
        if !ready { previewConfirmed=false }
    }
    public mutating func confirmPreview(phase:P3Phase,sessionRunning:Bool,humanVisible:Bool)->Bool {
        guard !invalidated,phase == .ready,sessionRunning,previewSignal,humanVisible else { return false }
        previewConfirmed=true;return true
    }
    public func mayRecord(phase:P3Phase,sessionRunning:Bool)->Bool {
        !invalidated && phase == .ready && sessionRunning &&
        (!scope.requiresInstructions || instructionsAcknowledged) &&
        (!scope.requiresPreview || (previewSignal && previewConfirmed))
    }
    public mutating func invalidate() { invalidated=true;previewConfirmed=false;previewSignal=false }
}
