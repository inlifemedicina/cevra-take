import Foundation

// Pure protocol gates: importing/constructing this type never accesses media hardware.
public enum P3Phase: String, Sendable { case idle, permission, preparing, ready, paused, starting, recording, finalizing, saved, failed }
public enum P3Event: Sendable { case prepare, permitted, prepared, record, started, stop, finished, persisted, recovered, pause, resume, fail }
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
        case (.permission,.pause),(.preparing,.pause),(.ready,.pause): next = .paused
        case (.paused,.resume): next = .permission
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
    case vertical="P3-ORIENTATION-VERTICAL-001", horizontal="P3-ORIENTATION-HORIZONTAL-001"
    case horizontalResume="P3-PREVIEW-RESUME-HORIZONTAL-001"
    case manualTextVertical="P4-MANUAL-TEXT-VERTICAL-001"
    case manualTextFrontVertical="P4-MANUAL-TEXT-FRONT-VERTICAL-001"
    public var hasManualText:Bool { self == .manualTextVertical || self == .manualTextFrontVertical }
    public var allowsCapture:Bool { self == .manualTextFrontVertical }
    public var cameraPolicy:P4CameraPolicy { self == .manualTextFrontVertical ? .frontProof : .rear }
    public var requiresInstructions:Bool { self == .retry002 || isOrientationProof || self == .horizontalResume || hasManualText }
    public var isOrientationProof:Bool { self == .vertical || self == .horizontal }
    public var axis:P3OrientationAxis? { (self == .vertical || hasManualText) ? .vertical : (self == .horizontal || self == .horizontalResume ? .horizontal : nil) }
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


public enum P3OrientationAxis:String, Sendable { case vertical,horizontal }
public enum P3Posture:String, Sendable {
    case portrait,portraitUpsideDown,landscapePortRight,landscapePortLeft,unknown
    // UIDevice raw values. The landscape names refer to the physical connector side,
    // which is opposite the UIKit landscape orientation name used for device rotation.
    public static func device(rawValue:Int)->Self {
        switch rawValue { case 1:return .portrait;case 2:return .portraitUpsideDown
        case 3:return .landscapePortRight;case 4:return .landscapePortLeft;default:return .unknown }
    }
    public var axis:P3OrientationAxis? {
        switch self { case .portrait,.portraitUpsideDown:return .vertical
        case .landscapePortRight,.landscapePortLeft:return .horizontal;case .unknown:return nil }
    }
}
public enum P4CameraPosition:String,Sendable { case back,front }
// Explicit proof policy; no media APIs, camera discovery or process/session state.
public struct P4CameraPolicy:Equatable,Sendable {
    public let position:P4CameraPosition
    public let previewMirrored:Bool
    public let originalMirrored:Bool
    public init(position:P4CameraPosition,previewMirrored:Bool,originalMirrored:Bool) {
        self.position=position;self.previewMirrored=previewMirrored;self.originalMirrored=originalMirrored
    }
    public static let rear=Self(position:.back,previewMirrored:false,originalMirrored:false)
    // Candidate proof setting; not a final product preference.
    public static let frontProof=Self(position:.front,previewMirrored:true,originalMirrored:false)
    public func previewReady(supported:Bool,mirrored:Bool,automatic:Bool)->Bool {
        supported && !automatic && mirrored == previewMirrored
    }
    public func admits(framePolicy:Self,captureSupported:Bool,captureMirrored:Bool,captureAutomatic:Bool)->Bool {
        framePolicy == self && captureSupported && !captureAutomatic && captureMirrored == originalMirrored
    }
}
public struct P3OrientationFrame:Equatable, Sendable {
    public let posture:P3Posture
    public let previewAngle:Double
    public let captureAngle:Double
    public let cameraPolicy:P4CameraPolicy
    public init(posture:P3Posture,previewAngle:Double,captureAngle:Double,cameraPolicy:P4CameraPolicy = .rear) {
        self.posture=posture;self.previewAngle=previewAngle;self.captureAngle=captureAngle;self.cameraPolicy=cameraPolicy
    }
    public func supported(for axis:P3OrientationAxis?,previewSupported:Bool,captureSupported:Bool)->Bool {
        guard let axis,posture.axis == axis else { return false }
        return previewSupported && captureSupported && previewAngle.isFinite && captureAngle.isFinite &&
            (0..<360).contains(previewAngle) && (0..<360).contains(captureAngle)
    }
}
public struct P3OrientationFreeze:Sendable {
    public private(set) var frame:P3OrientationFrame?
    public init() {}
    public mutating func lock(_ candidate:P3OrientationFrame,axis:P3OrientationAxis?,previewSupported:Bool,captureSupported:Bool)->Bool {
        guard frame == nil,candidate.supported(for:axis,previewSupported:previewSupported,captureSupported:captureSupported) else { return false }
        frame=candidate;return true
    }
}

// Provisional UI freeze while serial admission is pending; not a persistent claim.
// Rejection before start releases only this proposal, never the reserved attempt.
public struct P3OrientationStartTransaction:Sendable {
    public private(set) var pending:P3OrientationFrame?
    public private(set) var committed:P3OrientationFrame?
    public var frame:P3OrientationFrame? { committed ?? pending }
    public init() {}
    public mutating func propose(_ frame:P3OrientationFrame,axis:P3OrientationAxis?,previewSupported:Bool)->Bool {
        guard pending == nil,committed == nil,frame.supported(for:axis,previewSupported:previewSupported,captureSupported:true) else { return false }
        pending=frame;return true
    }
    @discardableResult public mutating func finish(accepted:Bool)->Bool {
        guard let pending else { return false }
        if accepted { committed=pending };self.pending=nil;return true
    }
    public static func admitted(_ proposed:P3OrientationFrame,latest:P3OrientationFrame?,consent:P3PreparationConsent,phase:P3Phase,sessionRunning:Bool)->Bool {
        latest == proposed && consent.mayRecord(phase:phase,sessionRunning:sessionRunning)
    }
}

// Generations are volatile callback cancellation, never attempt IDs or retry allocation.
public struct P3PreviewEpoch:Sendable {
    public private(set) var value:UInt64=0
    private var active=false
    public init() {}
    public mutating func begin()->UInt64 { value &+= 1;active=true;return value }
    public mutating func cancel() { value &+= 1;active=false }
    public func accepts(_ token:UInt64)->Bool { active && token == value }
}
// Serial admission controls when the exclusive filesystem operation may run.
// The persistent O_EXCL claim remains authoritative after process loss or write failure.
public struct P3StartClaimGate:Sendable {
    public private(set) var claimed=false
    public init() {}
    public mutating func reserve(admitted:Bool,exclusiveWrite:() throws -> Void) throws -> Bool {
        guard admitted,!claimed else { return false }
        try exclusiveWrite();claimed=true;return true
    }
}

// Harness-only ownership for its one process-wide audio session. No media/API calls here.
public enum P3AudioRole:Sendable { case capture,playback }
public struct P3AudioLease:Equatable,Sendable {
    public let role:P3AudioRole
    private let identity:UUID
    fileprivate init(role:P3AudioRole) { self.role=role;identity=UUID() }
}
public enum P3AudioOwnershipError:Error { case busy,configuration }
public final class P3AudioOwnership:@unchecked Sendable {
    private let lock=NSLock()
    private var owner:P3AudioLease?
    public init() {}
    public func acquire(_ role:P3AudioRole,reusing:P3AudioLease?,configure:(P3AudioRole) throws -> Void) throws -> P3AudioLease {
        lock.lock();defer { lock.unlock() }
        if let owner,owner == reusing,owner.role == role { return owner }
        guard owner == nil else { throw P3AudioOwnershipError.busy }
        try configure(role)
        let lease=P3AudioLease(role:role);owner=lease;return lease
    }
    @discardableResult public func release(_ lease:P3AudioLease,deactivate:() throws -> Void) throws -> Bool {
        lock.lock();defer { lock.unlock() }
        guard owner == lease else { return false }
        try deactivate();owner=nil;return true
    }
}
