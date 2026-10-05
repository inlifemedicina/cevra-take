import SwiftUI
import ManualTextProof
@preconcurrency import AVFoundation
import AVKit
import Foundation
import Darwin

// No camera/audio operation on initialization, default launch, or readonly entry.
private func p3Permission(_ media:AVMediaType) -> String {
    switch AVCaptureDevice.authorizationStatus(for:media) {
    case .authorized:return "authorized"
    case .denied:return "denied"
    case .restricted:return "restricted"
    case .notDetermined:return "notDetermined"
    @unknown default:return "unknown"
    }
}
private func p3Base() -> URL {
    FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
        .appendingPathComponent("P3CaptureSandbox",isDirectory:true)
}
private func p3Free(_ root:URL) throws -> Int64 {
    let values=try root.resourceValues(forKeys:[.volumeAvailableCapacityForImportantUsageKey,.volumeAvailableCapacityKey])
    guard let usable=values.volumeAvailableCapacityForImportantUsage,let physical=values.volumeAvailableCapacity,
          usable>=0,physical>=0 else { throw P3Error.spaceUnknown }
    return min(usable,Int64(physical))
}
private func p3ExclusiveJSON(_ value:[String:String],at path:URL) throws {
    let fd=open(path.path,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0o600)
    guard fd>=0 else {
        let code=errno
        if code==EEXIST { throw P3Error.destinationExists }
        throw POSIXError(POSIXErrorCode(rawValue:code) ?? .EIO)
    }
    defer { close(fd) }
    let data=try canonical(value)
    try data.withUnsafeBytes { bytes in
        var offset=0
        while offset<data.count {
            let n=Darwin.write(fd,bytes.baseAddress!.advanced(by:offset),data.count-offset)
            if n<0 && errno==EINTR { continue }
            guard n>0 else { throw P3Error.io };offset+=n
        }
    }
    guard fsync(fd)==0 else { throw P3Error.io }
}
private func p3SmallJSON(_ path:URL) throws -> [String:String] {
    let fd=open(path.path,O_RDONLY|O_NOFOLLOW)
    guard fd>=0 else { throw P3Error.integrity };defer { close(fd) }
    var statValue=stat()
    guard fstat(fd,&statValue)==0,(statValue.st_mode & S_IFMT)==S_IFREG,statValue.st_size>0,statValue.st_size<=4096 else { throw P3Error.integrity }
    let count=Int(statValue.st_size)
    var data=Data(count:count)
    try data.withUnsafeMutableBytes { bytes in
        var offset=0
        while offset<count {
            let n=Darwin.read(fd,bytes.baseAddress!.advanced(by:offset),count-offset)
            if n<0 && errno==EINTR { continue };guard n>0 else { throw P3Error.integrity };offset+=n
        }
    }
    guard let value=try JSONSerialization.jsonObject(with:data) as? [String:String] else { throw P3Error.integrity }
    return value
}
private enum P3Error: String, Error { case orientation, spaceUnknown, lowSpace, destinationExists, io, permission, unsupportedFormat, route, thermal, interruption, recording, profile, integrity }

// Serialize category/activation with lease checks; no takeover of another controller.
private enum P3AudioSession {
    private static let ownership=P3AudioOwnership()
    static func acquire(_ role:P3AudioRole,reusing:P3AudioLease?) throws -> P3AudioLease {
        try ownership.acquire(role,reusing:reusing) { role in
            let audio=AVAudioSession.sharedInstance()
            let category:AVAudioSession.Category=role == .capture ? .playAndRecord : .playback
            let mode:AVAudioSession.Mode=role == .capture ? .videoRecording : .default
            let options:AVAudioSession.CategoryOptions=role == .capture ? [.defaultToSpeaker] : []
            try audio.setCategory(category,mode:mode,options:options)
            guard audio.category == category,audio.mode == mode else { throw P3AudioOwnershipError.configuration }
            try audio.setActive(true)
        }
    }
    static func release(_ lease:P3AudioLease) throws {
        try ownership.release(lease) { try AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
    }
    static func errorCode(_ error:Error)->String {
        if let error=error as? P3AudioOwnershipError { return error == .busy ? "ownerBusy" : "configurationMismatch" }
        let error=error as NSError
        let domain=[NSOSStatusErrorDomain,AVFoundationErrorDomain,NSCocoaErrorDomain].contains(error.domain) ? error.domain : "other"
        return "\(domain):\(error.code)"
    }
}

// Readonly opt-in report: does not construct a capture controller or activate any sensor.
struct P3ReadinessScreen: View {
    @State private var text="P3 READONLY — sem sensores"
    var body: some View { VStack(spacing:16) {
        Text("P3 prontidão informativa").font(.title2)
        Text(text).accessibilityIdentifier("p3-readonly-status")
        Text("Não solicita permissões, preview ou sessão. Gravação exige comando humano coordenado.")
    }.padding().task {
        do {
            let a=CommandLine.arguments
            guard let i=a.firstIndex(of:"--p3-readiness-id"),i+1<a.count else { throw P3Error.io }
            let id=a[i+1]
            guard !id.isEmpty,id.count<=64,id.utf8.allSatisfy({ (65...90).contains($0)||(48...57).contains($0)||$0==45 }) else { throw P3Error.io }
            let root=p3Base()
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
            let free=try p3Free(root)
            let report:[String:String]=[
                "protocol":"P3-MIN-001","sensors":"NOT_RUN","freeBytes":String(free),
                "requiredStartBytes":String(P3Limits.startSpace),"spaceGate":free>=P3Limits.startSpace ? "PASS":"BLOCKED",
                "cameraPermission":p3Permission(.video),
                "microphonePermission":p3Permission(.audio),
                "pid":String(ProcessInfo.processInfo.processIdentifier),
                "expectedStoreSourceSHA256":"32a37818906c11d738d8eeb00318c86c3bc9c45ed07a1365cd9484f963cbb4df",
                "result":"READONLY_INFO","width":"1920","height":"1080","fps":"30","color":"SDR"]
            try p3ExclusiveJSON(report,at:root.appendingPathComponent("readiness-\(id).json"))
            text="P3_READONLY_INFO | espaço \(free) bytes | câmera/microfone NOT_RUN"
        } catch { text="ERROR: readonlyReport — sem sensores" }
    } }
}

private struct P3Media: Sendable {
    let duration:Double; let width:Int; let height:Int; let fps:Double
    let videos:Int; let audios:Int; let sdr:Bool
    var profileOK:Bool { P3Limits.fileProfile(duration:duration,width:width,height:height,fps:fps,videoTracks:videos,audioTracks:audios,sdrVerified:sdr) }
}
// All capture/state mutations are confined to q. Published UI updates run on main.
// AVFoundation delegates enqueue onto q; no AV object crosses a test harness.
final class P3CaptureController: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {
    @Published private(set) var phase=P3Phase.idle
    @Published private(set) var status="P3 NOT_RUN — aguarde coordenação humana"
    @Published private(set) var canPreview=false
    @Published private(set) var previewDevice:AVCaptureDevice?
    @Published private(set) var previewSessionStatus="Sessão: não verificada"
    @Published private(set) var playbackURL:URL?
    let session=AVCaptureSession()
    private let q=DispatchQueue(label:"org.cevra.proof.p3.session")
    private let output=AVCaptureMovieFileOutput()
    private var state=P3State()
    private var run:URL?
    private var failure:P3Error?
    private var observers:[NSObjectProtocol]=[]
    private var startTimeout:DispatchWorkItem?
    private var finishTimeout:DispatchWorkItem?
    private var captureTimeout:DispatchWorkItem?
    private var deadline=P3RecordingDeadline()
    private var watchdog:DispatchSourceTimer?
    private var configured=false
    private var captureAudioLease:P3AudioLease?
    @Published private(set) var audioSessionDiagnostic="Captura: sessão de áudio NOT_RUN"
    private let scope:P3AttemptScope
    private let textBinding:P4CaptureBinding?
    var manualRevision:ScriptRevision? { textBinding?.revision }
    private let baseURL:URL
    private var videoDevice:AVCaptureDevice?
    private var epoch=P3PreviewEpoch()
    private var startClaim=P3StartClaimGate()
    @Published private(set) var previewEpoch:UInt64=0
    private var orientationCandidate:P3OrientationFrame?
    private var orientationFreeze=P3OrientationFreeze()
    private var consent:P3PreparationConsent
    @Published private(set) var instructionsAcknowledged=false
    @Published private(set) var previewHumanConfirmed=false
    @Published private(set) var preparationFeedback=P3PreparationFeedback(phase:.idle,axis:nil,posture:nil,signalReady:false,confirmed:false,allowsCapture:false)
    @Published private(set) var fileFeedback=P3FileFeedback()
    private var displayPreviewReady=false
    init(scope:P3AttemptScope = .original) {
        self.scope=scope
        self.textBinding=scope.hasManualText ? try? P4CaptureBinding.fixedPT() : nil
        self.consent=P3PreparationConsent(scope:scope)
        self.baseURL=scope.base(in:p3Base())
        self.preparationFeedback=P3PreparationFeedback(phase:.idle,axis:scope.axis,posture:nil,signalReady:false,confirmed:false,allowsCapture:scope.allowsCapture)
        super.init()
    }
    private func publish(_ text:String) {
        let phase=state.phase
        DispatchQueue.main.async { self.phase=phase;self.status=text }
        publishPreparationFeedback()
    }
    private func publishPreparationFeedback() {
        let feedback=P3PreparationFeedback(phase:state.phase,axis:scope.axis,posture:orientationCandidate?.posture,signalReady:displayPreviewReady,confirmed:consent.previewConfirmed,allowsCapture:scope.allowsCapture)
        DispatchQueue.main.async { self.preparationFeedback=feedback }
    }
    private func safeThermal()->Bool {
        let t=ProcessInfo.processInfo.thermalState;return t != .serious && t != .critical
    }
    private func internalRoute()->Bool {
        let input=AVAudioSession.sharedInstance().currentRoute.inputs
        return input.count==1 && input[0].portType == .builtInMic
    }
    private func existingClaimOrResult()->Bool {
        FileManager.default.fileExists(atPath:baseURL.appendingPathComponent("ATTEMPT-RESERVED.json").path) ||
        FileManager.default.fileExists(atPath:baseURL.appendingPathComponent("LATEST.json").path)
    }
    func prepareByHuman() { q.async {
        guard self.scope.allowsCapture else { self.publish("Histórico — somente Reabrir/Play; sem novo preparo");return }
        guard !self.scope.hasManualText || self.textBinding != nil else { self.publish("BLOCKED — roteiro fixo indisponível; sem sensores");return }
        guard !self.existingClaimOrResult() else { self.publish("BLOCKED — tentativa já consumida; somente reabrir, sem reset");return }
        guard self.consent.mayPrepare(phase:self.state.phase),self.state.accept(.prepare) else { return }
        let token=self.epoch.begin()
        self.publish("PERMISSÕES — comando humano, tentativa ainda não consumida")
        AVCaptureDevice.requestAccess(for:.video) { video in self.q.async {
            guard self.epoch.accepts(token),self.state.phase == .permission else { return }
            guard video else { self.pausePreview("Permissão de câmera indisponível");return }
            AVCaptureDevice.requestAccess(for:.audio) { audio in self.q.async {
                guard self.epoch.accepts(token),self.state.phase == .permission else { return }
                guard audio else { self.pausePreview("Permissão de microfone indisponível");return }
                self.finishPreparation(token:token)
            } }
        } }
    } }
    // No requestAccess or automatic restart on resume; permissions must already be usable.
    func resumeByHuman() { q.async {
        guard self.scope.allowsCapture,self.state.phase == .paused,!self.existingClaimOrResult() else { return }
        guard AVCaptureDevice.authorizationStatus(for:.video) == .authorized,
              AVCaptureDevice.authorizationStatus(for:.audio) == .authorized else {
            self.publish("PAUSED — permissões não disponíveis; sem pedido ou retomada automática");return
        }
        guard self.state.accept(.resume) else { return }
        let token=self.epoch.begin();self.finishPreparation(token:token)
    } }
    private func finishPreparation(token:UInt64) {
        guard epoch.accepts(token),state.phase == .permission else { return }
        guard safeThermal(),let free=try? p3Free(p3Base().deletingLastPathComponent()),free>=P3Limits.startSpace else {
            pausePreview("Espaço/thermal não permite preview");return
        }
        guard state.accept(.permitted) else { return }
        do {
            if !configured { try prepareSession() }
            else {
                guard !session.isInterrupted else { pausePreview("Sessão ainda interrompida");return }
                let audio=AVAudioSession.sharedInstance()
                try acquireCaptureAudio()
                guard let builtIn=audio.availableInputs?.first(where:{$0.portType == .builtInMic}) else { pausePreview("Rota interna indisponível");return }
                try audio.setPreferredInput(builtIn)
                guard internalRoute() else { pausePreview("Rota interna não confirmada");return }
            }
            guard epoch.accepts(token),state.accept(.prepared) else { return }
            installSessionObservers(token:token)
            consent.observePreview(ready:false);orientationCandidate=nil;displayPreviewReady=false
            DispatchQueue.main.async { self.previewEpoch=token;self.previewHumanConfirmed=false;self.previewDevice=self.videoDevice;self.canPreview=true }
            publish("PREPARED — confirme NOVA imagem real e postura; tentativa não consumida")
            q.async {
                guard self.epoch.accepts(token),self.state.phase == .ready else { return }
                self.session.startRunning();self.publishPreviewSessionStatus()
                if !self.session.isRunning { self.pausePreview("Sessão não iniciou");return }
            }
        } catch let error as P3Error { fail(error) } catch { fail(.recording) }
    }
    private func pausePreview(_ reason:String) {
        guard state.accept(.pause) else { return }
        epoch.cancel();consent.observePreview(ready:false);orientationCandidate=nil;displayPreviewReady=false
        shutdown()
        DispatchQueue.main.async { self.previewHumanConfirmed=false }
        publish("PAUSED — "+reason+"; retomar somente por botão humano e nova confirmação; sem claim/RUN")
    }
    private func interruptBeforeOrDuringCapture(_ reason:String,error:P3Error) {
        if [.permission,.preparing,.ready].contains(state.phase) { pausePreview(reason) }
        else if [.starting,.recording].contains(state.phase) || (state.phase == .finalizing && !deadline.finished) { fail(error) }
    }
    private func prepareSession() throws {
        guard safeThermal() else { throw P3Error.thermal }
        guard try p3Free(p3Base().deletingLastPathComponent())>=P3Limits.startSpace else { throw P3Error.lowSpace }
        let wanted:AVCaptureDevice.Position=scope.cameraPolicy.position == .front ? .front : .back
        guard let device=AVCaptureDevice.default(.builtInWideAngleCamera,for:.video,position:wanted),
              device.position == wanted,
              let audio=AVCaptureDevice.default(for:.audio) else { throw P3Error.unsupportedFormat }
        guard let format=device.formats.first(where: {
            let d=CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            return d.width==1920 && d.height==1080 && $0.supportedColorSpaces.contains(.sRGB) &&
            $0.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate<=30 && $0.maxFrameRate>=30 })
        }) else { throw P3Error.unsupportedFormat }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canSetSessionPreset(.inputPriority) else { throw P3Error.unsupportedFormat }
        session.sessionPreset = .inputPriority
        let videoInput=try AVCaptureDeviceInput(device:device),audioInput=try AVCaptureDeviceInput(device:audio)
        guard session.canAddInput(videoInput),session.canAddInput(audioInput),session.canAddOutput(output) else { throw P3Error.unsupportedFormat }
        session.addInput(videoInput);session.addInput(audioInput);session.addOutput(output)
        try device.lockForConfiguration()
        device.activeFormat=format
        device.activeVideoMinFrameDuration=CMTime(value:1,timescale:30)
        device.activeVideoMaxFrameDuration=CMTime(value:1,timescale:30)
        device.automaticallyAdjustsVideoHDREnabled=false
        if format.isVideoHDRSupported { device.isVideoHDREnabled=false }
        device.activeColorSpace = .sRGB
        device.unlockForConfiguration()
        guard let connection=output.connection(with:.video),output.availableVideoCodecTypes.contains(.h264) else { throw P3Error.unsupportedFormat }
        // Mirror support is mandatory for this fixed proof; never fall back to rear.
        guard connection.isVideoMirroringSupported else { throw P3Error.unsupportedFormat }
        connection.automaticallyAdjustsVideoMirroring=false
        connection.isVideoMirrored=scope.cameraPolicy.originalMirrored
        guard scope.cameraPolicy.admits(framePolicy:scope.cameraPolicy,captureSupported:connection.isVideoMirroringSupported,
            captureMirrored:connection.isVideoMirrored,captureAutomatic:connection.automaticallyAdjustsVideoMirroring) else { throw P3Error.unsupportedFormat }
        // Rotation is chosen explicitly at the human start, never by fallback to 0.
        videoDevice=device
        let supported=output.supportedOutputSettingsKeys(for:connection)
        guard supported.contains(AVVideoCodecKey),supported.contains(AVVideoCompressionPropertiesKey) else { throw P3Error.unsupportedFormat }
        output.setOutputSettings([AVVideoCodecKey:AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:12_000_000]],for:connection)
        output.maxRecordedDuration=CMTime(seconds:P3Limits.seconds,preferredTimescale:600)
        output.minFreeDiskSpaceLimit=P3Limits.reserve
        let audioSession=AVAudioSession.sharedInstance()
        session.automaticallyConfiguresApplicationAudioSession=false
        try acquireCaptureAudio()
        guard let builtIn=audioSession.availableInputs?.first(where:{$0.portType == .builtInMic}) else { throw P3Error.route }
        try audioSession.setPreferredInput(builtIn)
        guard internalRoute() else { throw P3Error.route }
        configured=true
    }
    private func installSessionObservers(token:UInt64) {
        for observer in observers { NotificationCenter.default.removeObserver(observer) };observers.removeAll()
        for name in [AVCaptureSession.wasInterruptedNotification,AVCaptureSession.runtimeErrorNotification,
                     AVAudioSession.routeChangeNotification,ProcessInfo.thermalStateDidChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:nil) { [weak self] note in
                guard let self else { return };let name=note.name
                self.q.async {
                    guard self.epoch.accepts(token),[.permission,.preparing,.ready,.starting,.recording,.finalizing].contains(self.state.phase) else { return }
                    if name == ProcessInfo.thermalStateDidChangeNotification && self.safeThermal() { return }
                    if name == AVAudioSession.routeChangeNotification && self.internalRoute() { return }
                    self.interruptBeforeOrDuringCapture("Interrupção/rota/thermal",error:name == ProcessInfo.thermalStateDidChangeNotification ? .thermal : .interruption)
                }
            })
        }
    }
    // Read-only diagnostic. Never requests access, configures or starts a session.
    private func publishPreviewSessionStatus() {
        let running=session.isRunning, interrupted=session.isInterrupted
        let mic=p3Permission(.audio),route=internalRoute() ? "builtInMic" : "notConfirmed"
        DispatchQueue.main.async {
            self.previewSessionStatus="Sessão running=\(running), interrupted=\(interrupted); micPermission=\(mic), inputRoute=\(route)"
        }
    }
    func refreshPreviewDiagnosticByHuman() { q.async { self.publishPreviewSessionStatus() } }
    func acknowledgeInstructionsByHuman() { q.async {
        guard self.state.phase == .idle else { return }
        self.consent.acknowledgeInstructions()
        let acknowledged=self.consent.instructionsAcknowledged
        DispatchQueue.main.async { self.instructionsAcknowledged=acknowledged }
    } }
    func observePreviewSignal(ready:Bool,orientation:P3OrientationFrame?,generation:UInt64) { q.async {
        guard self.epoch.accepts(generation),self.state.phase == .ready else { return }
        if self.orientationFreeze.frame == nil && self.orientationCandidate != orientation {
            self.consent.observePreview(ready:false)
        }
        if self.orientationFreeze.frame == nil { self.orientationCandidate=orientation }
        let supported=orientation?.supported(for:self.scope.axis,previewSupported:true,captureSupported:true) == true &&
            orientation?.cameraPolicy == self.scope.cameraPolicy
        self.consent.observePreview(ready:ready && supported)
        self.displayPreviewReady=ready && supported
        self.publishPreparationFeedback()
        let confirmed=self.consent.previewConfirmed
        DispatchQueue.main.async { self.previewHumanConfirmed=confirmed }
    } }
    func confirmPreviewByHuman(signalReady:Bool,generation:UInt64) { q.async {
        guard self.epoch.accepts(generation),signalReady,self.consent.confirmPreview(phase:self.state.phase,sessionRunning:self.session.isRunning,humanVisible:true) else { return }
        self.publishPreparationFeedback()
        DispatchQueue.main.async { self.previewHumanConfirmed=true }
    } }
    func recordByHuman(orientation:P3OrientationFrame,generation:UInt64,completion:@escaping(Bool)->Void) { q.async { [self] in
        func reply(_ accepted:Bool) { DispatchQueue.main.async { completion(accepted) } }
        guard self.configured,self.state.phase == .ready,self.epoch.accepts(generation) else { reply(false);return }
        guard orientation.cameraPolicy == self.scope.cameraPolicy,
              P3OrientationStartTransaction.admitted(orientation,latest:self.orientationCandidate,consent:self.consent,
                phase:self.state.phase,sessionRunning:self.session.isRunning) else {
            self.consent.observePreview(ready:false);self.displayPreviewReady=false
            self.publish("BLOCKED antes do start — orientação/preview mudou; atualize e reconfirme imagem real; reserva preservada")
            DispatchQueue.main.async { self.previewHumanConfirmed=false };reply(false);return
        }
        do {
            guard let connection=self.output.connection(with:.video),
                  self.videoDevice?.position == (self.scope.cameraPolicy.position == .front ? AVCaptureDevice.Position.front : .back),
                  self.scope.cameraPolicy.admits(framePolicy:orientation.cameraPolicy,captureSupported:connection.isVideoMirroringSupported,
                    captureMirrored:connection.isVideoMirrored,captureAutomatic:connection.automaticallyAdjustsVideoMirroring),
                  self.orientationFreeze.lock(orientation,axis:self.scope.axis,previewSupported:true,
                    captureSupported:connection.isVideoRotationAngleSupported(CGFloat(orientation.captureAngle))) else { throw P3Error.orientation }
            connection.videoRotationAngle=CGFloat(orientation.captureAngle)
            guard Double(connection.videoRotationAngle)==orientation.captureAngle,
                  self.scope.cameraPolicy.admits(framePolicy:orientation.cameraPolicy,captureSupported:connection.isVideoMirroringSupported,
                    captureMirrored:connection.isVideoMirrored,captureAutomatic:connection.automaticallyAdjustsVideoMirroring) else { throw P3Error.orientation }
            let base=baseURL;let free=try p3Free(p3Base().deletingLastPathComponent())
            guard P3Limits.mayStart(free:free,internalMic:self.internalRoute(),
                permissions:AVCaptureDevice.authorizationStatus(for:.video) == .authorized && AVCaptureDevice.authorizationStatus(for:.audio) == .authorized,
                thermalSafe:self.safeThermal()) else { throw P3Error.lowSpace }
            guard try self.startClaim.reserve(admitted:self.epoch.accepts(generation) && self.scope.allowsCapture,exclusiveWrite: {
                try FileManager.default.createDirectory(at:base,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
                try p3ExclusiveJSON(["protocol":"P3-MIN-001","attempt":self.scope.rawValue],at:base.appendingPathComponent("ATTEMPT-RESERVED.json"))
            }) else { throw P3Error.destinationExists }
            let dir=base.appendingPathComponent("P3-RUN-"+UUID().uuidString,isDirectory:true)
            guard mkdir(dir.path,0o700)==0 else { throw P3Error.destinationExists }
            try p3ExclusiveJSON(["protocol":"P3-MIN-001","source":"capture.mov","freeBeforeBytes":String(free)],at:dir.appendingPathComponent("capture.claim.json"))
            let file=dir.appendingPathComponent("capture.mov")
            guard !FileManager.default.fileExists(atPath:file.path),self.state.accept(.record),self.deadline.begin() else { throw P3Error.destinationExists }
            self.run=dir;self.publish("STARTING — um clipe local, não repetir comando")
            self.output.startRecording(to:file,recordingDelegate:self)
            let timeout=DispatchWorkItem { [weak self] in
                guard let self,self.deadline.startExpired() else { return };self.fail(.recording)
            }
            self.startTimeout=timeout;self.q.asyncAfter(deadline:.now()+5,execute:timeout)
            reply(true)
        } catch let e as P3Error { self.fail(e);reply(false) } catch { self.fail(.io);reply(false) }
    } }
    func stopByHuman() { q.async { [self] in
        guard self.state.accept(.stop),self.deadline.requestStop() else { return }
        self.publish("FINALIZING — parada solicitada; duração curta não recebe PASS")
        let timeout=DispatchWorkItem { [weak self] in
            guard let self,self.deadline.finishExpired() else { return };self.fail(.recording)
        }
        self.finishTimeout=timeout;self.q.asyncAfter(deadline:.now()+5,execute:timeout)
        if self.output.isRecording { self.output.stopRecording() }
    } }
    func suspend() { q.async { self.interruptBeforeOrDuringCapture("App fora do primeiro plano/preview pausado",error:.interruption) } }
    func pauseByHuman() { q.async { self.pausePreview("Pausa solicitada pelo proprietário") } }
    private func fail(_ error:P3Error) {
        epoch.cancel();consent.invalidate()
        failure=error;deadline.cancel();state.accept(.fail);startTimeout?.cancel();finishTimeout?.cancel();captureTimeout?.cancel();watchdog?.cancel();watchdog=nil
        publish("FAIL: "+error.rawValue+" — original preservado, sem sucesso declarado")
        if output.isRecording { output.stopRecording() }
        shutdown()
    }
    private func acquireCaptureAudio() throws {
        do {
            captureAudioLease=try P3AudioSession.acquire(.capture,reusing:captureAudioLease)
            DispatchQueue.main.async { self.audioSessionDiagnostic="Captura: playAndRecord/videoRecording/defaultToSpeaker ativa — sem PASS de qualidade" }
        } catch {
            let code=P3AudioSession.errorCode(error)
            DispatchQueue.main.async { self.audioSessionDiagnostic="CAPTURE_AUDIO_FAIL — "+code };throw error
        }
    }
    private func shutdown() {
        if configured { session.stopRunning() }
        if let lease=captureAudioLease {
            do {
                try P3AudioSession.release(lease);captureAudioLease=nil
                DispatchQueue.main.async { self.audioSessionDiagnostic="Captura: sessão de áudio liberada" }
            } catch {
                let code=P3AudioSession.errorCode(error)
                DispatchQueue.main.async { self.audioSessionDiagnostic="AUDIO_RELEASE_FAIL — "+code+"; lease retido, sem desativar outro proprietário" }
            }
        }
        DispatchQueue.main.async { self.canPreview=false;self.previewDevice=nil }
    }
    func fileOutput(_ output:AVCaptureFileOutput,didStartRecordingTo url:URL,from connections:[AVCaptureConnection]) {
        q.async { [self] in
            guard self.deadline.startCallback(),self.state.accept(.started) else {
                self.fail(.recording);return
            }
            self.startTimeout?.cancel();self.publish("RECORDING — parada automática em 30 s")
            let completeTimeout=DispatchWorkItem { [weak self] in
                guard let self,self.deadline.completionExpired() else { return };self.fail(.recording)
            }
            self.captureTimeout=completeTimeout
            self.q.asyncAfter(deadline:.now()+P3Limits.seconds+5,execute:completeTimeout)
            let timer=DispatchSource.makeTimerSource(queue:self.q)
            timer.schedule(deadline:.now()+0.5,repeating:0.5)
            timer.setEventHandler { [weak self] in
                guard let self,let run=self.run,self.state.phase == .recording else { return }
                if !self.safeThermal() { self.fail(.thermal);return }
                if !self.internalRoute() { self.fail(.route);return }
                guard let free=try? p3Free(run),free>=P3Limits.reserve else { self.fail(.lowSpace);return }
            }
            self.watchdog=timer;timer.resume()
        }
    }
    func fileOutput(_ output:AVCaptureFileOutput,didFinishRecordingTo url:URL,from connections:[AVCaptureConnection],error:Error?) {
        let ns=error as NSError?
        let durationEnd=ns?.domain == AVFoundationErrorDomain && ns?.code == AVError.maximumDurationReached.rawValue &&
            (ns?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool == true)
        let good=error == nil || durationEnd
        q.async {
            self.startTimeout?.cancel();self.finishTimeout?.cancel();self.captureTimeout?.cancel();self.watchdog?.cancel();self.watchdog=nil
            self.shutdown()
            guard self.failure == nil,good,self.deadline.finishCallback(),self.state.accept(.finished),let root=self.run else { self.fail(self.failure ?? .recording);return }
            self.publish("FINALIZING — validar arquivo e persistir")
            Task.detached(priority:.utility) {
                do {
                    let media=try await Self.inspect(url)
                    let original=try Store.describeOriginal(id:"O",source:url)
                    let bytes=Int64(original.byteCount)
                    guard bytes <= (Int64.max-P3Limits.reserve)/2,try p3Free(root)>=P3Limits.reserve+2*bytes else { throw P3Error.lowSpace }
                    let snapshot=self.textBinding?.snapshot(original) ?? P3Limits.snapshot(original),project=root.appendingPathComponent("project")
                    try Store(project).commitFiles(snapshot,sources:["O":url])
                    let (reopened,files)=try Store(project).loadFiles()
                    guard reopened==snapshot,let copy=files["O"],try Store.describeOriginal(id:"O",source:copy)==original else { throw P3Error.integrity }
                    var report:[String:String]=["protocol":"P3-MIN-001","physical":"OBSERVED_FILE_ONLY",
                        "durationSeconds":String(media.duration),"width":String(media.width),"height":String(media.height),
                        "nominalFPS":String(media.fps),"videoTracks":String(media.videos),"audioTracks":String(media.audios),
                        "sdrVerified":String(media.sdr),"sha256":original.sha256,"bytes":String(original.byteCount),
                        "takeRevision":"R1","synthetic":"false","profile":media.profileOK ? "PASS":"FAIL",
                        "playbackHuman":"PENDING","sync":"NOT_MEASURED","frameLoss":"NOT_MEASURED",
                        "attempt":self.scope.rawValue,
                        "postureAtStart":self.orientationFreeze.frame?.posture.rawValue ?? "unknown",
                        "captureRotationAngle":String(self.orientationFreeze.frame?.captureAngle ?? -1),
                        "previewRotationAngle":String(self.orientationFreeze.frame?.previewAngle ?? -1),
                        "cameraPosition":self.scope.cameraPolicy.position.rawValue,
                        "previewMirroredAtConfirmation":String(self.orientationFreeze.frame?.cameraPolicy.previewMirrored ?? false),
                        "originalMirroredVerifiedAtStart":String(self.scope.cameraPolicy.originalMirrored),
                        "automaticMirroringDisabledAtStart":"true"]
                    if let binding=self.textBinding { report.merge(binding.report) { _,new in new } }
                    try p3ExclusiveJSON(report,at:root.appendingPathComponent("result.json"))
                    try p3ExclusiveJSON(["protocol":"P3-MIN-001","run":root.lastPathComponent],at:self.baseURL.appendingPathComponent("LATEST.json"))
                    self.q.async {
                        guard self.state.accept(.persisted) else { return }
                        let feedback=P3FileFeedback(integrity:.verified,profile:media.profileOK ? .pass:.fail,reportedFPS:media.fps)
                        DispatchQueue.main.async { self.fileFeedback=feedback }
                        self.publish(media.profileOK ? "FILE_PROFILE_PERSISTENCE_PASS — reprodução humana PENDING" : "FILE_SAVED_PROFILE_FAIL — original preservado")
                    }
                } catch let e as P3Error { self.q.async { self.fail(e) } }
                catch { self.q.async { self.fail(.integrity) } }
            }
        }
    }
    private static func inspect(_ url:URL) async throws -> P3Media {
        let asset=AVURLAsset(url:url)
        let duration=try await asset.load(.duration).seconds
        let video=try await asset.loadTracks(withMediaType:.video),audio=try await asset.loadTracks(withMediaType:.audio)
        guard let track=video.first else { throw P3Error.profile }
        let size=try await track.load(.naturalSize),fps=try await track.load(.nominalFrameRate)
        let formats=try await track.load(.formatDescriptions)
        // Require explicit SDR transfer evidence, never infer SDR from absence of HDR tags.
        let sdr = !formats.isEmpty && formats.allSatisfy { f in
            let value=CMFormatDescriptionGetExtension(f,extensionKey:kCMFormatDescriptionExtension_TransferFunction)
            guard let value=value as? String else { return false }
            return value == (kCMFormatDescriptionTransferFunction_ITU_R_709_2 as String) || value == (kCMFormatDescriptionTransferFunction_sRGB as String)
        }
        return P3Media(duration:duration,width:Int(size.width),height:Int(size.height),fps:Double(fps),videos:video.count,audios:audio.count,sdr:sdr)
    }
    func reopenByHuman() { q.async {
        guard [.idle,.saved].contains(self.state.phase) else { return }
        do {
            let root:URL
            if let existing=self.run { root=existing } else {
                let pointer=try p3SmallJSON(self.baseURL.appendingPathComponent("LATEST.json"))
                guard
                      pointer["protocol"] == "P3-MIN-001",let name=pointer["run"],name.hasPrefix("P3-RUN-"),
                      let uuid=UUID(uuidString:String(name.dropFirst(7))),name == "P3-RUN-"+uuid.uuidString else { throw P3Error.integrity }
                root=self.baseURL.appendingPathComponent(name,isDirectory:true)
            }
            let (s,files)=try Store(root.appendingPathComponent("project")).loadFiles()
            guard s.projectID == "P3-CAPTURE-001",!s.takes[0].synthetic,let url=files["O"],
                  try Store.describeOriginal(id:"O",source:url)==s.originals[0] else { throw P3Error.integrity }
            if let binding=self.textBinding { guard binding.matches(s) else { throw P3Error.integrity } }
            if self.state.phase == .idle { guard self.state.accept(.recovered) else { throw P3Error.integrity } }
            let recorded=try? p3SmallJSON(root.appendingPathComponent("result.json"))
            let feedback=P3FileFeedback.recorded(recorded,matching:s.originals[0])
            DispatchQueue.main.async { self.fileFeedback=feedback }
            self.run=root;self.publish("REOPEN_HASH_PASS — áudio/imagem humanos PENDING")
            DispatchQueue.main.async { self.playbackURL=url;self.status="REOPEN_HASH_PASS — toque Play e avalie áudio/imagem" }
        } catch {
            DispatchQueue.main.async { self.fileFeedback=P3FileFeedback(integrity:.verificationFailed,profile:self.fileFeedback.profile,reportedFPS:self.fileFeedback.reportedFPS,independentlyMeasuredAverageFPS:self.fileFeedback.independentlyMeasuredAverageFPS) }
            self.fail(.integrity)
        }
    } }
}
// Main-thread view layout owns the backing preview layer's dimensions. A sublayer
// sized in updateUIView can remain zero-sized after SwiftUI's initial layout.
private final class P3PreviewView:UIView {
    override class var layerClass:AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer:AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var report:((String,Bool,P3OrientationFrame?)->Void)?
    var axis:P3OrientationAxis?
    private var policy=P4CameraPolicy.rear
    private var cameraMatches=false
    private var coordinator:AVCaptureDevice.RotationCoordinator?
    private var observations:[NSKeyValueObservation]=[]
    private var notification:NSObjectProtocol?
    private var tracking=false
    private var transaction=P3OrientationStartTransaction()
    private var lastReport:String?
    func configure(device:AVCaptureDevice,axis:P3OrientationAxis?,policy:P4CameraPolicy) {
        self.axis=axis;self.policy=policy
        cameraMatches=device.position == (policy.position == .front ? AVCaptureDevice.Position.front : .back)
        coordinator=AVCaptureDevice.RotationCoordinator(device:device,previewLayer:previewLayer)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications();tracking=true
        notification=NotificationCenter.default.addObserver(forName:UIDevice.orientationDidChangeNotification,object:nil,queue:.main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.reportDiagnostic() }
        }
        if let coordinator {
            for key in [\AVCaptureDevice.RotationCoordinator.videoRotationAngleForHorizonLevelPreview,\AVCaptureDevice.RotationCoordinator.videoRotationAngleForHorizonLevelCapture] {
                observations.append(coordinator.observe(key,options:[.new]) { [weak self] _,_ in
                    Task { @MainActor [weak self] in self?.reportDiagnostic() }
                })
            }
        }
    }
    func stopTracking() {
        if tracking { UIDevice.current.endGeneratingDeviceOrientationNotifications();tracking=false }
        if let notification { NotificationCenter.default.removeObserver(notification) };notification=nil
        observations.removeAll();coordinator=nil
    }
    override func layoutSubviews() { super.layoutSubviews();reportDiagnostic() }
    private func mirroringReady()->Bool {
        guard cameraMatches,let c=previewLayer.connection,c.isVideoMirroringSupported else { return false }
        // No mirroring changes after a provisional/committed human start.
        if transaction.frame == nil {
            c.automaticallyAdjustsVideoMirroring=false;c.isVideoMirrored=policy.previewMirrored
        }
        return policy.previewReady(supported:c.isVideoMirroringSupported,mirrored:c.isVideoMirrored,automatic:c.automaticallyAdjustsVideoMirroring)
    }
    private func candidate()->P3OrientationFrame? {
        guard mirroringReady() else { return nil }
        if let frozen=transaction.frame { return frozen }
        guard window != nil,bounds.width>0,bounds.height>0,let coordinator else { return nil }
        let posture=P3Posture.device(rawValue:UIDevice.current.orientation.rawValue)
        guard posture.axis != nil else { return nil }
        return P3OrientationFrame(posture:posture,
            previewAngle:Double(coordinator.videoRotationAngleForHorizonLevelPreview),
            captureAngle:Double(coordinator.videoRotationAngleForHorizonLevelCapture),cameraPolicy:policy)
    }
    func proposeForHumanStart()->P3OrientationFrame? {
        guard let frame=candidate(),let connection=previewLayer.connection,
              connection.isActive,connection.isEnabled,previewLayer.isPreviewing,
              transaction.propose(frame,axis:axis,previewSupported:connection.isVideoRotationAngleSupported(CGFloat(frame.previewAngle))) else { return nil }
        connection.videoRotationAngle=CGFloat(frame.previewAngle)
        guard mirroringReady() else {
            transaction.finish(accepted:false);lastReport=nil;reportDiagnostic();return nil
        }
        return transaction.frame
    }
    func finishHumanStart(accepted:Bool) {
        transaction.finish(accepted:accepted);lastReport=nil;reportDiagnostic()
    }
    func reportDiagnostic() {
        let c=previewLayer.connection,frame=candidate()
        let rotationOK=frame?.supported(for:axis,
            previewSupported:frame.map { c?.isVideoRotationAngleSupported(CGFloat($0.previewAngle)) == true } ?? false,captureSupported:true) == true
        if rotationOK,let frame,let c { c.videoRotationAngle=CGFloat(frame.previewAngle) }
        let mirrorOK=mirroringReady()
        let ready=rotationOK && mirrorOK && window != nil && bounds.width>0 && bounds.height>0 && c?.isEnabled == true && c?.isActive == true && previewLayer.isPreviewing
        let text="Preview bounds=\(Int(bounds.width))×\(Int(bounds.height)), active=\(c?.isActive ?? false), previewing=\(previewLayer.isPreviewing), posture=\(frame?.posture.rawValue ?? "unknown"), previewAngle=\(frame?.previewAngle ?? -1), captureAngle=\(frame?.captureAngle ?? -1), frozen=\(transaction.frame != nil), orientationGate=\(rotationOK), camera=\(policy.position.rawValue), previewMirror=\(c?.isVideoMirrored ?? false), mirrorGate=\(mirrorOK)"
        guard text != lastReport else { return };lastReport=text
        let callback=report;DispatchQueue.main.async { callback?(text,ready,frame) }
    }
}
extension P3AttemptScope:Identifiable { public var id:String { rawValue } }
private struct P3Preview:UIViewRepresentable {
    let session:AVCaptureSession
    let device:AVCaptureDevice
    let axis:P3OrientationAxis?
    let cameraPolicy:P4CameraPolicy
    let diagnosticRevision:Int
    let report:(String,Bool,P3OrientationFrame?)->Void
    let available:(P3PreviewView)->Void
    func makeUIView(context:Context)->P3PreviewView {
        let view=P3PreviewView();view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session=session;view.report=report;view.configure(device:device,axis:axis,policy:cameraPolicy)
        DispatchQueue.main.async { available(view) };return view
    }
    func updateUIView(_ view:P3PreviewView,context:Context) { view.report=report;view.reportDiagnostic() }
    static func dismantleUIView(_ view:P3PreviewView,coordinator:()) { view.stopTracking() }
}
// Retained independently of SwiftUI body recomputation. The URL is supplied only
// after the human reopen command has passed Store/hash validation; no autoplay.
@MainActor
private final class P3PlaybackController:ObservableObject {
    let player=AVPlayer()
    @Published private(set) var diagnostic="Playback NOT_RUN"
    private var url:URL?
    private var audioLease:P3AudioLease?
    private var audioDiagnostic="Sessão playback NOT_RUN"
    private var audioNotifications:[NSObjectProtocol]=[]
    private var errorLogCount=0
    private var lastErrorCode="none"
    private var observations:[NSKeyValueObservation]=[]
    private var notifications:[NSObjectProtocol]=[]
    func loadVerifiedLocalFile(_ url:URL) {
        guard self.url != url else { return }
        pause()
        observations.removeAll()
        for token in notifications { NotificationCenter.default.removeObserver(token) }
        notifications.removeAll()
        guard url.isFileURL,FileManager.default.isReadableFile(atPath:url.path) else {
            diagnostic="PLAYBACK_BLOCKED — arquivo local não legível";return
        }
        self.url=url;errorLogCount=0;lastErrorCode="none"
        // Store preserves originals under O.bin. Declare the known MOV container
        // through the public SDK; never rename/copy/link or change stored metadata.
        let asset=AVURLAsset(url:url,options:[AVURLAssetOverrideMIMETypeKey:"video/quicktime"])
        let item=AVPlayerItem(asset:asset)
        player.replaceCurrentItem(with:item)
        observations.append(item.observe(\.status,options:[.initial,.new]) { [weak self] _,_ in
            Task { @MainActor [weak self] in self?.refresh() }
        })
        observations.append(player.observe(\.timeControlStatus,options:[.initial,.new]) { [weak self] _,_ in
            Task { @MainActor [weak self] in self?.refresh() }
        })
        for name in [AVPlayerItem.failedToPlayToEndTimeNotification,AVPlayerItem.newErrorLogEntryNotification] {
            notifications.append(NotificationCenter.default.addObserver(forName:name,object:item,queue:.main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            })
        }
        refresh()
    }
    private func errorCode(_ error:Error?)->String {
        guard let e=error as NSError? else { return "none" }
        // Raw descriptions/userInfo/log URI can expose container paths. Never print.
        let domain=[AVFoundationErrorDomain,NSCocoaErrorDomain,NSURLErrorDomain,NSOSStatusErrorDomain].contains(e.domain) ? e.domain : "other"
        return "\(domain):\(e.code)"
    }
    func refresh() {
        guard let item=player.currentItem else { return }
        if item.status == .failed { stopAndRelease() }
        report(item)
        item.fetchErrorLog { [weak self,weak item] log in
            let count=log?.events.count ?? 0
            let code=log?.events.last.map { String($0.errorStatusCode) } ?? "none"
            Task { @MainActor [weak self,weak item] in
                guard let self,let item,self.player.currentItem === item else { return }
                self.errorLogCount=count;self.lastErrorCode=code;self.report(item)
            }
        }
    }
    private func report(_ item:AVPlayerItem) {
        let state:String
        switch item.status { case .unknown:state="unknown";case .readyToPlay:state="readyToPlay";case .failed:state="failed";@unknown default:state="unrecognized" }
        let time=player.currentTime().seconds
        let seconds=time.isFinite ? String(format:"%.2f",time) : "unknown"
        diagnostic="Item=\(state), control=\(player.timeControlStatus.rawValue), rate=\(player.rate), time=\(seconds)s, error=\(errorCode(item.error ?? player.error)), errorLogCount=\(errorLogCount), lastErrorCode=\(lastErrorCode), \(audioDiagnostic) — qualidade humana não aprovada"
    }
    func playByHuman() {
        guard url != nil,let item=player.currentItem,item.status == .readyToPlay else {
            audioDiagnostic="PLAYBACK_BLOCKED — item não pronto; nenhuma ativação/Play";refresh();return
        }
        do {
            let lease=try P3AudioSession.acquire(.playback,reusing:audioLease)
            audioLease=lease;audioDiagnostic="Sessão playback/default ativa — qualidade humana PENDING"
            installAudioNotifications(item:item,lease:lease)
            player.play();refresh()
        } catch {
            audioDiagnostic="PLAYBACK_AUDIO_FAIL — "+P3AudioSession.errorCode(error)+"; Play não executado"
            refresh()
        }
    }
    private func installAudioNotifications(item:AVPlayerItem,lease:P3AudioLease) {
        for token in audioNotifications { NotificationCenter.default.removeObserver(token) };audioNotifications.removeAll()
        for name in [AVPlayerItem.didPlayToEndTimeNotification,AVPlayerItem.failedToPlayToEndTimeNotification] {
            audioNotifications.append(NotificationCenter.default.addObserver(forName:name,object:item,queue:.main) { [weak self,weak item] _ in
                Task { @MainActor [weak self,weak item] in
                    guard let self,let item,self.player.currentItem === item,self.audioLease == lease else { return }
                    self.pause()
                }
            })
        }
        audioNotifications.append(NotificationCenter.default.addObserver(forName:AVAudioSession.didBecomeInactiveNotification,object:AVAudioSession.sharedInstance(),queue:.main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,self.audioLease == lease else { return };self.pause()
                // No interruption-end activation or resume.
            }
        })
    }
    private func stopAndRelease() {
        player.pause()
        for token in audioNotifications { NotificationCenter.default.removeObserver(token) };audioNotifications.removeAll()
        if let lease=audioLease {
            do { try P3AudioSession.release(lease);audioLease=nil;audioDiagnostic="Sessão playback liberada — sem auto-resume" }
            catch { audioDiagnostic="AUDIO_RELEASE_FAIL — "+P3AudioSession.errorCode(error)+"; lease retido" }
        }
    }
    func pause() { stopAndRelease();refresh() }
    deinit {
        player.pause()
        if let lease=audioLease { try? P3AudioSession.release(lease) }
        for token in notifications+audioNotifications { NotificationCenter.default.removeObserver(token) }
    }

}
private struct P3PlaybackView:View {
    let url:URL
    let suspended:Bool
    @StateObject private var playback=P3PlaybackController()
    @Environment(\.scenePhase) private var scene
    var body:some View { VStack {
        VideoPlayer(player:playback.player).frame(height:240)
        Text(playback.diagnostic).accessibilityIdentifier("p3-playback-diagnostic")
        Button("Play do original reaberto — comando humano") { playback.playByHuman() }
        Button("Pausar reprodução") { playback.pause() }
        Button("Atualizar diagnóstico de reprodução — sem gravar") { playback.refresh() }
    }.onAppear { playback.loadVerifiedLocalFile(url) }
    .onChange(of:url) { _,value in playback.loadVerifiedLocalFile(value) }
    .onChange(of:suspended) { _,value in if value { playback.pause() } }
    .onChange(of:scene) { _,value in if value != .active { playback.pause() } }
    .onDisappear { playback.pause() }
    }
}
struct P3CaptureScreen:View {
    private let scope:P3AttemptScope
    @StateObject private var controller:P3CaptureController
    init(scope:P3AttemptScope = .original) {
        self.scope=scope
        _controller=StateObject(wrappedValue:P3CaptureController(scope:scope))
    }
    @Environment(\.scenePhase) private var scene
    @Environment(\.locale) private var feedbackLocale
    private var feedbackLanguage:P3FeedbackLanguage { P3FeedbackLanguage(localeIdentifier:feedbackLocale.identifier) }
    @State private var previewDiagnostic="Preview: não verificado"
    @State private var diagnosticRevision=0
    @State private var previewSignalReady=false
    @State private var selectedScope:P3AttemptScope?
    @State private var previewView:P3PreviewView?
    @State private var showTextSamples=false
    private var activeManualCapture:Bool { scope.hasManualText && [.starting,.recording,.finalizing].contains(controller.phase) }
    var body:some View { ScrollView { VStack(spacing:16) {
        Text(scope == .manualTextFrontVertical ? "P4 — frontal + roteiro vertical" : (scope.hasManualText ? "P4 — roteiro + captura vertical" : (scope == .original ? "P3 — originais preservados" : "P3 — prova "+(scope.axis?.rawValue ?? "histórica")))).font(.title2)
        if !activeManualCapture { Text("Somente após coordenação: objeto neutro e voz. Sem Photos, upload, IA ou rede.") }
        Text(controller.preparationFeedback.text(feedbackLanguage)).accessibilityIdentifier("p3-preparation-feedback")
        if !activeManualCapture && controller.fileFeedback.integrity != .notChecked {
            VStack(alignment:.leading,spacing:6) {
                Text(controller.fileFeedback.integrityText(feedbackLanguage))
                Text(controller.fileFeedback.profileText(feedbackLanguage))
                Text(controller.fileFeedback.targetText(feedbackLanguage))
                Text(controller.fileFeedback.reportedFPSText(feedbackLanguage))
                Text(controller.fileFeedback.averageFPSText(feedbackLanguage))
                Text(controller.fileFeedback.playbackText(feedbackLanguage))
            }.accessibilityIdentifier("p3-file-feedback")
        }
        DisclosureGroup(feedbackLanguage.text("Detalhes técnicos do estado","Technical state details")) {
            Text(controller.status).accessibilityIdentifier("p3-status")
        }
        if !activeManualCapture { Text(controller.audioSessionDiagnostic) }
        if scope == .manualTextFrontVertical && !activeManualCapture {
            Text("Prova frontal: prévia espelhada; vídeo salvo sem espelhar. Conferir letras/lados no original após Play.")
        }
        if scope.requiresInstructions && !activeManualCapture {
            Text(scope.hasManualText ? "0. Após coordenação: mantenha VERTICAL, objeto neutro, leia o roteiro sintético EM VOZ ALTA. Toque/role o texto nos 30 s, sem sair do app. Sem imagem real, não grave." : "0. Antes de preparar: mantenha a posição desta prova: \(scope.axis?.rawValue ?? "histórica"), filme objeto neutro e conte EM VOZ ALTA de 1 em diante durante os 30 s. Não saia do app até salvar. Sem imagem real, não grave. Depois reabra/Play e confira voz e orientação.")
            Button(scope.hasManualText ? "Entendi posição vertical e leitura em voz alta — comando humano" : "Entendi posição desta prova e contagem em voz alta — comando humano") {
                controller.acknowledgeInstructionsByHuman()
            }.disabled(controller.phase != .idle)
        }
        if !activeManualCapture {
        Button("1. Preparar permissões e câmera — comando humano") { controller.prepareByHuman() }
            .disabled(!scope.allowsCapture || controller.phase != .idle || (scope.requiresInstructions && !controller.instructionsAcknowledged))
        Button("Pausar preview — sem consumir tentativa") { controller.pauseByHuman() }.disabled(controller.phase != .ready)
        Button("Retomar preview — comando humano; nova confirmação obrigatória") { controller.resumeByHuman() }.disabled(controller.phase != .paused || !scope.allowsCapture)
        }
        if controller.canPreview,let device=controller.previewDevice {
            let generation=controller.previewEpoch
            P3Preview(session:controller.session,device:device,axis:scope.axis,cameraPolicy:scope.cameraPolicy,diagnosticRevision:diagnosticRevision,report: { text,ready,orientation in
                guard controller.previewEpoch == generation,controller.canPreview else { return }
                previewDiagnostic=text;previewSignalReady=ready;controller.observePreviewSignal(ready:ready,orientation:orientation,generation:generation)
            },available: { if controller.previewEpoch == generation { previewView=$0 } }).id(generation).frame(height:scope.hasManualText ? 150 : 220)
            if !activeManualCapture {
            Text(controller.previewSessionStatus)
            Text(previewDiagnostic).accessibilityIdentifier("p3-preview-diagnostic")
            Button("Atualizar diagnóstico de preview — sem gravar") {
                controller.refreshPreviewDiagnosticByHuman();diagnosticRevision += 1
            }
            }
        }
        if scope.requiresPreview && !activeManualCapture {
            Text("Primeira tomada preservada. Esta tentativa não apaga nem substitui LATEST/original anterior.")
            Button("Confirmo imagem real visível no preview — comando humano") {
                controller.confirmPreviewByHuman(signalReady:previewSignalReady,generation:controller.previewEpoch)
            }.disabled(!previewSignalReady || controller.phase != .ready)
        }
        if !activeManualCapture {
        Button("2. Gravar 30 s — orientação congelada, mantenha posição") {
            guard let view=previewView,let frame=view.proposeForHumanStart() else { previewSignalReady=false;return }
            controller.recordByHuman(orientation:frame,generation:controller.previewEpoch) { accepted in view.finishHumanStart(accepted:accepted) }
        }
            .disabled(controller.phase != .ready || (scope.requiresPreview && (!previewSignalReady || !controller.previewHumanConfirmed)))
        }
        Button("Parar antecipadamente — duração não aprovada") { controller.stopByHuman() }.disabled(![.starting,.recording].contains(controller.phase))
        if let revision=controller.manualRevision {
            ManualPrompter(revision:revision,fontSize:22).id(revision.identity.sha256).frame(height:320)
        }
        Button("3. Reabrir original e habilitar Play") { controller.reopenByHuman() }.disabled(![.idle,.saved].contains(controller.phase))
        if let url=controller.playbackURL { P3PlaybackView(url:url,suspended:selectedScope != nil || showTextSamples) }
        if scope == .original {
            Button("Amostras P4 PT/EN por toque — sem sensores") { showTextSamples=true }.disabled(![.idle,.saved].contains(controller.phase))
            Button("Abrir P4 FRONTAL + roteiro VERTICAL — aguarde coordenação") { selectedScope = .manualTextFrontVertical }.disabled(![.idle,.saved].contains(controller.phase))
            Button("Reabrir P4 traseira — somente leitura e Play") { selectedScope = .manualTextVertical }.disabled(![.idle,.saved].contains(controller.phase))
            Button("Reabrir retomada HORIZONTAL — somente leitura e Play") { selectedScope = .horizontalResume }
                .disabled(![.idle,.saved].contains(controller.phase))
            Button("Reabrir VERTICAL — somente leitura e Play") { selectedScope = .vertical }
                .disabled(![.idle,.saved].contains(controller.phase))
            Button("Reabrir HORIZONTAL consumida — sem novo preparo") { selectedScope = .horizontal }
                .disabled(![.idle,.saved].contains(controller.phase))
            Button("Reabrir tomada 002 — somente leitura e Play") { selectedScope = .retry002 }
                .disabled(![.idle,.saved].contains(controller.phase))
        }
    }.padding() }.onChange(of:scene) { _,value in if value == .background { controller.suspend() } }
    .onChange(of:controller.canPreview) { _,visible in if !visible { previewSignalReady=false;previewView=nil;previewDiagnostic="Preview pausado — nova confirmação necessária" } }
    .onDisappear { controller.suspend() }
    .sheet(item:$selectedScope) { P3CaptureScreen(scope:$0) }
    .sheet(isPresented:$showTextSamples) { P4MobileTextSamples() }
    }
}
