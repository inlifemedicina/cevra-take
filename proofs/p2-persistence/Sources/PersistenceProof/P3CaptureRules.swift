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
    case cameraSettings="P4-CAMERA-SETTINGS-001"
    case cadenceValidation="P4-30FPS-CADENCE-002-ATTEMPT-001"
    public var hasCaptureSettings:Bool { self == .cameraSettings || self == .cadenceValidation }
    public var hasManualText:Bool { self == .manualTextVertical || self == .manualTextFrontVertical || hasCaptureSettings }
    public var allowsCapture:Bool { self == .cadenceValidation }
    public func acceptsCaptureConfiguration(_ configuration:P4CaptureConfiguration?)->Bool {
        guard allowsCapture,let configuration else { return false }
        return configuration.mode.isOffered && configuration.camera.modes.contains(configuration.mode) && configuration.mode.fps==30
    }
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


public enum P3OrientationAxis:String, Sendable {
    case vertical,horizontal
    public func choiceText(_ language:P3FeedbackLanguage)->String {
        self == .vertical ? language.text("Vertical","Portrait"):language.text("Horizontal","Landscape")
    }
}
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


// Presentation only: these values never admit capture or change stored results.
public enum P3FeedbackLanguage:Equatable,Sendable {
    case pt,en
    public init(localeIdentifier:String) { self=localeIdentifier.lowercased().hasPrefix("en") ? .en:.pt }
    public func text(_ pt:String,_ en:String)->String { self == .pt ? pt:en }
}

// First settings panel: native adapters supply capabilities; fixtures never discover hardware.
public struct P4VideoMode:Hashable,Sendable {
    public let width:Int,height:Int,fps:Int
    public init(width:Int,height:Int,fps:Int) { self.width=width;self.height=height;self.fps=fps }
    public var label:String { "\(width)×\(height) · \(fps) fps · SDR" }
    public var isOffered:Bool { Self.offeredFPS.contains(fps) && [(1280,720),(1920,1080),(3840,2160)].contains { $0.0==width && $0.1==height } }
    public static let offeredFPS=[24,25,30,50,60]
    public static func supported(width:Int,height:Int,ranges:[ClosedRange<Double>],sdr:Bool)->[Self] {
        guard sdr,[(1280,720),(1920,1080),(3840,2160)].contains(where:{$0.0==width && $0.1==height}) else { return [] }
        return offeredFPS.filter { fps in ranges.contains { $0.contains(Double(fps)) } }.map { Self(width:width,height:height,fps:$0) }
    }
    public func fileProfile(duration:Double,width:Int,height:Int,fps:Double,videoTracks:Int,audioTracks:Int,sdr:Bool)->Bool {
        duration.isFinite && (29...31).contains(duration) &&
        ((width==self.width && height==self.height) || (width==self.height && height==self.width)) &&
        fps.isFinite && abs(fps-Double(self.fps))<=0.001 && videoTracks==1 && audioTracks>=1 && sdr
    }
    // A separately versioned future30 criterion; never reevaluates a stored result.
    public func cadenceProfile(duration:Double,width:Int,height:Int,videoTracks:Int,audioTracks:Int,sdr:Bool,
                               cadence:P4CadenceResult)->P3StoredProfileFeedback {
        guard self.fps==30 else { return .unavailable }
        guard isOffered,duration.isFinite,(29...31).contains(duration),
              ((width==self.width && height==self.height) || (width==self.height && height==self.width)),
              videoTracks==1,audioTracks>=1,sdr else { return .fail }
        switch cadence.status { case .pass:return .pass;case .fail:return .fail;case .unavailable:return .unavailable }
    }
}
public struct P4CameraCapability:Sendable,Equatable {
    public let id:String,position:P4CameraPosition,modes:[P4VideoMode]
    public init(id:String,position:P4CameraPosition,modes:[P4VideoMode]) { self.id=id;self.position=position;self.modes=modes }
}
public struct P4MicrophoneCapability:Sendable,Equatable {
    // Native UID is ephemeral, kept in memory only; report stores the input kind.
    public let id:String,name:String,kind:String
    public init(id:String,name:String,kind:String) { self.id=id;self.name=name;self.kind=kind }
}
public struct P4CaptureConfiguration:Equatable,Sendable {
    public let camera:P4CameraCapability,mode:P4VideoMode,axis:P3OrientationAxis
    public let previewMirrored:Bool,originalMirrored:Bool,microphone:P4MicrophoneCapability
    public init(camera:P4CameraCapability,mode:P4VideoMode,axis:P3OrientationAxis,previewMirrored:Bool,originalMirrored:Bool,microphone:P4MicrophoneCapability) {
        self.camera=camera;self.mode=mode;self.axis=axis;self.previewMirrored=previewMirrored;self.originalMirrored=originalMirrored;self.microphone=microphone
    }
    public var policy:P4CameraPolicy { P4CameraPolicy(position:camera.position,previewMirrored:previewMirrored,originalMirrored:originalMirrored) }
    public func positionText(_ language:P3FeedbackLanguage)->String {
        language.text("Posição deste preparo: ","Position for this preparation: ")+axis.choiceText(language)
    }
    public func isAvailable(cameras:[P4CameraCapability],microphones:[P4MicrophoneCapability])->Bool {
        cameras.contains { $0.id==camera.id && $0.position==camera.position && $0.modes.contains(mode) } && microphones.contains(microphone)
    }
    public func routeMatches(ids:[String])->Bool { ids == [microphone.id] }
    public func appliedMatches(cameraID:String,mode:P4VideoMode,minimumDuration:Double,maximumDuration:Double,inputIDs:[String])->Bool {
        cameraID==camera.id && mode==self.mode && minimumDuration.isFinite && maximumDuration.isFinite &&
        abs(minimumDuration-1/Double(mode.fps))<=1e-9 && abs(maximumDuration-1/Double(mode.fps))<=1e-9 && routeMatches(ids:inputIDs)
    }
    public func mayStart(free:Int64?,inputIDs:[String],permissions:Bool,thermalSafe:Bool)->Bool {
        guard let free else { return false }
        return free>=P3Limits.startSpace && routeMatches(ids:inputIDs) && permissions && thermalSafe
    }
    public var report:[String:String] {
        ["settingsVersion":"P4-CAMERA-SETTINGS-001","configuredWidth":String(mode.width),"configuredHeight":String(mode.height),
         "configuredFPS":String(mode.fps),"configuredOrientation":axis.rawValue,"configuredCamera":camera.position.rawValue,
         "configuredPreviewMirror":String(previewMirrored),"configuredOriginalMirror":String(originalMirrored),
         "configuredInputKind":microphone.kind,"codec":"H264","colorProfile":"SDR",
         "appliedWidth":String(mode.width),"appliedHeight":String(mode.height),"appliedFPS":String(mode.fps),
         "appliedInputKind":microphone.kind,"settingsVerifiedAtStart":"true"]
    }
}
public struct P4SettingsDraft:Sendable {
    public var cameraID:String?,mode:P4VideoMode?,microphoneID:String?
    public var axis=P3OrientationAxis.vertical,previewMirrored=true,originalMirrored=false
    public private(set) var committed:P4CaptureConfiguration?
    public init() {}
    public var editable:Bool { committed == nil }
    public mutating func returnToEditing() { committed=nil }
    public mutating func chooseCamera(_ id:String?) { guard editable else { return };cameraID=id;mode=nil }
    public mutating func commit(cameras:[P4CameraCapability],microphones:[P4MicrophoneCapability])->P4CaptureConfiguration? {
        guard editable,let camera=cameras.first(where:{$0.id==cameraID}),let mode,mode.isOffered,camera.modes.contains(mode),
              let microphone=microphones.first(where:{$0.id==microphoneID}) else { return nil }
        let config=P4CaptureConfiguration(camera:camera,mode:mode,axis:axis,previewMirrored:previewMirrored,originalMirrored:originalMirrored,microphone:microphone)
        committed=config;return config
    }
}
// Volatile presentation identity only. Each confirmed configuration owns a fresh
// SwiftUI controller; this UUID is never a namespace, reservation or stored ID.
public struct P4SettingsPreparation:Identifiable,Sendable {
    public let id=UUID()
    public let configuration:P4CaptureConfiguration
    public init(configuration:P4CaptureConfiguration) { self.configuration=configuration }
}
public struct P4RecordedSettings:Equatable,Sendable {
    public let mode:P4VideoMode,axis:P3OrientationAxis,policy:P4CameraPolicy,inputKind:String
    public init?(report:[String:String],expectedAttempt:P3AttemptScope?=nil) {
        if let expectedAttempt {
            guard expectedAttempt.hasCaptureSettings,report["attempt"]==expectedAttempt.rawValue else { return nil }
            if expectedAttempt == .cadenceValidation {
                guard report["profileCriteriaVersion"]==P4CadenceResult.version,
                      report["configuredFPS"]=="30",report["appliedFPS"]=="30" else { return nil }
            }
        }
        guard report["settingsVersion"]==P3AttemptScope.cameraSettings.rawValue,report["settingsVerifiedAtStart"]=="true",
              let width=report["configuredWidth"].flatMap(Int.init),let height=report["configuredHeight"].flatMap(Int.init),
              let fps=report["configuredFPS"].flatMap(Int.init),
              let axis=report["configuredOrientation"].flatMap(P3OrientationAxis.init(rawValue:)),
              let position=report["configuredCamera"].flatMap(P4CameraPosition.init(rawValue:)),
              let preview=report["configuredPreviewMirror"].flatMap(Bool.init),let original=report["configuredOriginalMirror"].flatMap(Bool.init),
              let kind=report["configuredInputKind"],
              ["MicrophoneBuiltIn","HeadsetMic","USBAudio","BluetoothHFP","LineIn","CarAudio"].contains(kind),
              report["appliedWidth"]==String(width),report["appliedHeight"]==String(height),report["appliedFPS"]==String(fps),report["appliedInputKind"]==kind
        else { return nil }
        let mode=P4VideoMode(width:width,height:height,fps:fps);guard mode.isOffered else { return nil }
        self.mode=mode;self.axis=axis;self.policy=P4CameraPolicy(position:position,previewMirrored:preview,originalMirrored:original);self.inputKind=kind
    }
    public func text(_ language:P3FeedbackLanguage)->String {
        let camera=policy.position == .front ? language.text("frontal","front"):language.text("traseira","back")
        let position=axis == .vertical ? language.text("vertical","portrait"):language.text("horizontal","landscape")
        let input=inputKind == "MicrophoneBuiltIn" ? language.text("interno","built-in"):inputKind
        let prefix=language.text("Configurações registradas no início, somente leitura: ","Settings recorded at start, read only: ")+mode.label+" · "+camera+" · "+position
        let mirror=language.text(" · prévia espelhada="," · mirrored preview=")+String(policy.previewMirrored)+language.text(" · original espelhado="," · mirrored original=")+String(policy.originalMirrored)
        return prefix+mirror+language.text(" · áudio="," · audio=")+input
    }
}
public struct P3PreparationFeedback:Equatable,Sendable {
    public let phase:P3Phase
    public let axis:P3OrientationAxis?
    public let posture:P3Posture?
    public let signalReady:Bool
    public let confirmed:Bool
    public let allowsCapture:Bool
    public init(phase:P3Phase,axis:P3OrientationAxis?,posture:P3Posture?,signalReady:Bool,confirmed:Bool,allowsCapture:Bool) {
        self.phase=phase;self.axis=axis;self.posture=posture;self.signalReady=signalReady;self.confirmed=confirmed;self.allowsCapture=allowsCapture
    }
    public func text(_ language:P3FeedbackLanguage)->String {
        let position=axis == .horizontal ? language.text("horizontal","horizontal"):language.text("vertical","vertical")
        switch phase {
        case .starting:return language.text("Iniciando gravação. Mantenha a posição e o app aberto.","Starting recording. Keep your position and the app open.")
        case .recording:return language.text("Gravando. Mantenha a posição até salvar.","Recording. Keep your position until saved.")
        case .finalizing:return language.text("Finalizando e salvando o original. Aguarde nesta tela.","Finishing and saving the original. Stay on this screen.")
        case .saved:return language.text("Original salvo. Confira separadamente integridade, perfil e reprodução.","Original saved. Check integrity, profile and playback separately.")
        case .failed:return language.text("Operação interrompida. Consulte o estado; não repita nem apague a tentativa.","Operation interrupted. Check the state; do not repeat or delete the attempt.")
        default:break
        }
        guard allowsCapture else { return language.text("Histórico preservado: somente Reabrir e Play.","Preserved history: Reopen and Play only.") }
        switch phase {
        case .idle:return language.text("Aguardando preparo por comando humano. Sensores ainda não iniciados.","Waiting for a human prepare command. Sensors have not started.")
        case .permission,.preparing:return language.text("Preparando permissões e prévia. Ainda não gravando.","Preparing permissions and preview. Not recording yet.")
        case .paused:return language.text("Prévia pausada. Retome e confirme uma nova imagem antes de gravar.","Preview paused. Resume and confirm a new image before recording.")
        case .ready:
            if let axis,posture?.axis != axis {
                return language.text("Gravação bloqueada: mantenha o aparelho "+position+" e confirme nova imagem. A prévia pode continuar visível.","Recording blocked: hold the device "+position+" and confirm a new image. The preview may remain visible.")
            }
            guard signalReady else { return language.text("Gravação bloqueada: aguarde uma prévia pronta e confira a imagem real.","Recording blocked: wait for a ready preview and check the real image.") }
            return confirmed ? language.text("Imagem confirmada. Início somente pelo botão de gravação.","Image confirmed. Start only with the recording button."):language.text("Confirmação pendente: confira e confirme a imagem real antes de gravar.","Confirmation pending: check and confirm the real image before recording.")
        default:return language.text("Confira o estado antes de continuar.","Check the state before continuing.")
        }
    }
}
public enum P3IntegrityFeedback:Equatable,Sendable { case notChecked,verified,verificationFailed }
public enum P3StoredProfileFeedback:Equatable,Sendable { case unavailable,pass,fail }
public struct P3FileFeedback:Equatable,Sendable {
    public let integrity:P3IntegrityFeedback
    public let profile:P3StoredProfileFeedback
    public let reportedFPS:Double?
    public let independentlyMeasuredAverageFPS:Double?
    public let configuredFPS:Double?
    public init(integrity:P3IntegrityFeedback = .notChecked,profile:P3StoredProfileFeedback = .unavailable,reportedFPS:Double? = nil,independentlyMeasuredAverageFPS:Double? = nil,configuredFPS:Double? = 30) {
        self.integrity=integrity;self.profile=profile
        self.reportedFPS=Self.finiteFPS(reportedFPS)
        self.independentlyMeasuredAverageFPS=Self.finiteFPS(independentlyMeasuredAverageFPS)
        self.configuredFPS=Self.finiteFPS(configuredFPS)
    }
    private static func finiteFPS(_ value:Double?)->Double? {
        guard let value,value.isFinite,value>=0 else { return nil };return value
    }
    // Auxiliary recorded evidence, not an authenticated manifest or a new analysis.
    public static func recorded(_ report:[String:String]?,matching original:Original,requiresSettingsReport:Bool=false,settingsScope:P3AttemptScope = .cameraSettings)->Self {
        let fallback:Double?=requiresSettingsReport ? nil:30
        guard let report,report["sha256"]==original.sha256,report["bytes"]==String(original.byteCount) else { return Self(integrity:.verified,configuredFPS:fallback) }
        if requiresSettingsReport {
            guard settingsScope.hasCaptureSettings,report["attempt"]==settingsScope.rawValue,
                  report["settingsVersion"]==P3AttemptScope.cameraSettings.rawValue else { return Self(integrity:.verified,configuredFPS:nil) }
            if settingsScope == .cadenceValidation && P4RecordedSettings(report:report,expectedAttempt:settingsScope) == nil {
                return Self(integrity:.verified,configuredFPS:nil)
            }
        }
        let profile:P3StoredProfileFeedback
        switch report["profile"] { case "PASS":profile = .pass;case "FAIL":profile = .fail;default:profile = .unavailable }
        let settingsAttempt=report["attempt"].flatMap(P3AttemptScope.init(rawValue:))?.hasCaptureSettings == true
        let target:Double?=settingsAttempt ? report["configuredFPS"].flatMap(Int.init).flatMap { P4VideoMode.offeredFPS.contains($0) ? Double($0):nil }:30
        let average=report["profileCriteriaVersion"]==P4CadenceResult.version ? report["timestampAverageFPS"].flatMap(Double.init):nil
        return Self(integrity:.verified,profile:profile,reportedFPS:report["nominalFPS"].flatMap(Double.init),independentlyMeasuredAverageFPS:average,configuredFPS:target)
    }
    public func integrityText(_ language:P3FeedbackLanguage)->String {
        switch integrity {
        case .notChecked:return language.text("Integridade: ainda não conferida.","Integrity: not checked yet.")
        case .verified:return language.text("Integridade: original conferido. Isso não aprova o perfil ou a reprodução.","Integrity: original checked. This does not approve profile or playback.")
        case .verificationFailed:return language.text("Integridade: conferência não concluída; original preservado.","Integrity: verification did not complete; original preserved.")
        }
    }
    public func profileText(_ language:P3FeedbackLanguage)->String {
        switch profile {
        case .unavailable:return language.text("Perfil registrado: indisponível; não inferir aprovação.","Recorded profile: unavailable; do not infer approval.")
        case .pass:return language.text("Perfil registrado: PASS. Reprodução humana continua separada.","Recorded profile: PASS. Human playback remains separate.")
        case .fail:return language.text("Perfil registrado: FAIL. Reabrir ou Play não altera esse resultado.","Recorded profile: FAIL. Reopen or Play does not change this result.")
        }
    }
    private func value(_ fps:Double?,_ language:P3FeedbackLanguage)->String {
        guard let fps else { return language.text("não medido","not measured") }
        let value=String(format:"%.6f",fps)
        return (language == .pt ? value.replacingOccurrences(of:".",with:","):value)+" fps"
    }
    public func targetText(_ language:P3FeedbackLanguage)->String {
        let target=configuredFPS.map { fps in fps.rounded()==fps ? String(format:"%.0f",fps)+" fps":value(fps,language) } ?? language.text("não medido","not measured")
        return language.text("Alvo configurado: ","Configured target: ")+target+language.text(". Não é uma medição do arquivo.",". This is not a file measurement.")
    }
    public func reportedFPSText(_ language:P3FeedbackLanguage)->String {
        language.text("FPS informado pela API do arquivo: ","FPS reported by the file API: ")+value(reportedFPS,language)
    }
    public func averageFPSText(_ language:P3FeedbackLanguage)->String {
        language.text("Média temporal independente: ","Independent timestamp average: ")+value(independentlyMeasuredAverageFPS,language)
    }
    public func playbackText(_ language:P3FeedbackLanguage)->String {
        language.text("Reprodução humana: use Play e avalie imagem e voz; nenhum aceite humano é registrado por estes indicadores.","Human playback: use Play and assess image and voice; these indicators do not record human acceptance.")
    }
}
