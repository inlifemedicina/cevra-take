import SwiftUI
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
private enum P3Error: String, Error { case spaceUnknown, lowSpace, destinationExists, io, permission, unsupportedFormat, route, thermal, interruption, recording, profile, integrity }

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
    private var audioActive=false
    private let isRetry:Bool
    private let baseURL:URL
    private var previewConfirmed=false
    @Published private(set) var previewHumanConfirmed=false
    init(isRetry:Bool=false) {
        self.isRetry=isRetry
        self.baseURL=isRetry ? p3Base().appendingPathComponent("P3-RETRY-001",isDirectory:true) : p3Base()
        super.init()
    }
    private func publish(_ text:String) {
        let phase=state.phase
        DispatchQueue.main.async { self.phase=phase;self.status=text }
    }
    private func safeThermal()->Bool {
        let t=ProcessInfo.processInfo.thermalState;return t != .serious && t != .critical
    }
    private func internalRoute()->Bool {
        let input=AVAudioSession.sharedInstance().currentRoute.inputs
        return input.count==1 && input[0].portType == .builtInMic
    }
    func prepareByHuman() {
        q.async {
            guard !FileManager.default.fileExists(atPath:self.baseURL.appendingPathComponent("LATEST.json").path) else {
                self.publish("P3 já salvo — reabra sem ativar sensores; não repetir captura");return
            }
            guard self.state.phase == .idle else { return }
            if self.isRetry {
                var step="createRetryDirectory"
                do {
                    try FileManager.default.createDirectory(at:self.baseURL,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
                    step="reserveExclusiveClaim"
                    try p3ExclusiveJSON(["protocol":"P3-MIN-001","attempt":"P3-RETRY-001"],at:self.baseURL.appendingPathComponent("ATTEMPT-RESERVED.json"))
                } catch let error as P3Error {
                    self.fail(error)
                    if error == .destinationExists {
                        self.publish("BLOCKED: reserva existente — tentativa consumida; sem reset, exclusão ou nova gravação")
                    } else { self.publish("FAIL: "+error.rawValue+" — etapa="+step+"; original preservado") }
                    return
                } catch {
                    self.fail(.io)
                    let e=error as NSError
                    let domain=[NSCocoaErrorDomain,NSPOSIXErrorDomain].contains(e.domain) ? e.domain : "other"
                    self.publish("FAIL: io — etapa=\(step), erro=\(domain):\(e.code); original preservado")
                    return
                }
            }
            guard self.state.accept(.prepare) else { return }
            self.publish("PERMISSÕES — comando humano")
            AVCaptureDevice.requestAccess(for:.video) { video in
                self.q.async {
                guard self.state.phase == .permission else { return }
                guard video else { self.fail(.permission);return }
                AVCaptureDevice.requestAccess(for:.audio) { audio in
                    self.q.async {
                        guard audio else { self.fail(.permission);return }
                        guard self.state.accept(.permitted) else { return }
                        do { try self.prepareSession();guard self.state.accept(.prepared) else { throw P3Error.recording }
                            self.publish("PREPARED — traseira/1080p30 SDR/microfone interno; captura NOT_RUN")
                            DispatchQueue.main.async { self.canPreview=true }
                        } catch let e as P3Error { self.fail(e) } catch { self.fail(.recording) }
                    }
                }
                }
            }
        }
    }
    private func prepareSession() throws {
        guard safeThermal() else { throw P3Error.thermal }
        let base=baseURL;try FileManager.default.createDirectory(at:base,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
        guard try p3Free(base)>=P3Limits.startSpace else { throw P3Error.lowSpace }
        guard let device=AVCaptureDevice.default(.builtInWideAngleCamera,for:.video,position:.back),
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
        if connection.isVideoRotationAngleSupported(0) { connection.videoRotationAngle=0 }
        let supported=output.supportedOutputSettingsKeys(for:connection)
        guard supported.contains(AVVideoCodecKey),supported.contains(AVVideoCompressionPropertiesKey) else { throw P3Error.unsupportedFormat }
        output.setOutputSettings([AVVideoCodecKey:AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:12_000_000]],for:connection)
        output.maxRecordedDuration=CMTime(seconds:P3Limits.seconds,preferredTimescale:600)
        output.minFreeDiskSpaceLimit=P3Limits.reserve
        let audioSession=AVAudioSession.sharedInstance()
        session.automaticallyConfiguresApplicationAudioSession=false
        try audioSession.setCategory(.playAndRecord,mode:.videoRecording,options:[.defaultToSpeaker])
        try audioSession.setActive(true)
        audioActive=true
        guard let builtIn=audioSession.availableInputs?.first(where:{$0.portType == .builtInMic}) else { throw P3Error.route }
        try audioSession.setPreferredInput(builtIn)
        guard internalRoute() else { throw P3Error.route }
        // Commit before startRunning; both operations are serial and off MainActor.
        configured=true
        q.async {
            guard self.state.phase == .ready else { return }
            self.session.startRunning()
            self.publishPreviewSessionStatus()
            if !self.session.isRunning { self.fail(.recording) }
        }
        for name in [AVCaptureSession.wasInterruptedNotification,AVCaptureSession.runtimeErrorNotification,
                     AVAudioSession.routeChangeNotification,ProcessInfo.thermalStateDidChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:nil) { [weak self] note in
                guard let self else { return };let name=note.name
                self.q.async {
                    guard [.ready,.starting,.recording].contains(self.state.phase) else { return }
                    if name == ProcessInfo.thermalStateDidChangeNotification && self.safeThermal() { return }
                    if name == AVAudioSession.routeChangeNotification && self.internalRoute() { return }
                    self.fail(name == ProcessInfo.thermalStateDidChangeNotification ? .thermal : .interruption)
                }
            })
        }
    }
    // Read-only diagnostic. Never requests access, configures or starts a session.
    private func publishPreviewSessionStatus() {
        let running=session.isRunning, interrupted=session.isInterrupted
        DispatchQueue.main.async {
            self.previewSessionStatus="Sessão running=\(running), interrupted=\(interrupted)"
        }
    }
    func refreshPreviewDiagnosticByHuman() { q.async { self.publishPreviewSessionStatus() } }
    func confirmPreviewByHuman(signalReady:Bool) { q.async {
        guard self.isRetry,self.state.phase == .ready,self.session.isRunning,signalReady else { return }
        self.previewConfirmed=true
        DispatchQueue.main.async { self.previewHumanConfirmed=true }
    } }
    func recordByHuman() { q.async { [self] in
        guard self.state.phase == .ready,self.configured,self.session.isRunning,(!self.isRetry || self.previewConfirmed) else { return }
        do {
            let base=baseURL;let free=try p3Free(base)
            guard P3Limits.mayStart(free:free,internalMic:self.internalRoute(),
                permissions:AVCaptureDevice.authorizationStatus(for:.video) == .authorized && AVCaptureDevice.authorizationStatus(for:.audio) == .authorized,
                thermalSafe:self.safeThermal()) else { throw P3Error.lowSpace }
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
        } catch let e as P3Error { self.fail(e) } catch { self.fail(.io) }
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
    func suspend() { q.async {
        if [.permission,.preparing,.ready,.starting,.recording].contains(self.state.phase) ||
           (self.state.phase == .finalizing && !self.deadline.finished) { self.fail(.interruption) }
    } }
    private func fail(_ error:P3Error) {
        failure=error;deadline.cancel();state.accept(.fail);startTimeout?.cancel();finishTimeout?.cancel();captureTimeout?.cancel();watchdog?.cancel();watchdog=nil
        publish("FAIL: "+error.rawValue+" — original preservado, sem sucesso declarado")
        if output.isRecording { output.stopRecording() }
        shutdown()
    }
    private func shutdown() {
        if session.isRunning { session.stopRunning() }
        if audioActive {
            try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
            audioActive=false
        }
        DispatchQueue.main.async { self.canPreview=false }
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
                    let snapshot=P3Limits.snapshot(original),project=root.appendingPathComponent("project")
                    try Store(project).commitFiles(snapshot,sources:["O":url])
                    let (reopened,files)=try Store(project).loadFiles()
                    guard reopened==snapshot,let copy=files["O"],try Store.describeOriginal(id:"O",source:copy)==original else { throw P3Error.integrity }
                    let report:[String:String]=["protocol":"P3-MIN-001","physical":"OBSERVED_FILE_ONLY",
                        "durationSeconds":String(media.duration),"width":String(media.width),"height":String(media.height),
                        "nominalFPS":String(media.fps),"videoTracks":String(media.videos),"audioTracks":String(media.audios),
                        "sdrVerified":String(media.sdr),"sha256":original.sha256,"bytes":String(original.byteCount),
                        "takeRevision":"R1","synthetic":"false","profile":media.profileOK ? "PASS":"FAIL",
                        "playbackHuman":"PENDING","sync":"NOT_MEASURED","frameLoss":"NOT_MEASURED"]
                    try p3ExclusiveJSON(report,at:root.appendingPathComponent("result.json"))
                    try p3ExclusiveJSON(["protocol":"P3-MIN-001","run":root.lastPathComponent],at:self.baseURL.appendingPathComponent("LATEST.json"))
                    self.q.async {
                        guard self.state.accept(.persisted) else { return }
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
            if self.state.phase == .idle { guard self.state.accept(.recovered) else { throw P3Error.integrity } }
            self.run=root;self.publish("REOPEN_HASH_PASS — áudio/imagem humanos PENDING")
            DispatchQueue.main.async { self.playbackURL=url;self.status="REOPEN_HASH_PASS — toque Play e avalie áudio/imagem" }
        } catch { self.fail(.integrity) }
    } }
}
// Main-thread view layout owns the backing preview layer's dimensions. A sublayer
// sized in updateUIView can remain zero-sized after SwiftUI's initial layout.
private final class P3PreviewView:UIView {
    override class var layerClass:AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer:AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var report:((String,Bool)->Void)?
    private var lastReport:String?
    override func layoutSubviews() {
        super.layoutSubviews()
        reportDiagnostic()
    }
    func reportDiagnostic() {
        let c=previewLayer.connection
        let text="Preview bounds=\(Int(bounds.width))×\(Int(bounds.height)), connection=\(c != nil), enabled=\(c?.isEnabled ?? false), active=\(c?.isActive ?? false), previewing=\(previewLayer.isPreviewing)"
        guard text != lastReport else { return }
        lastReport=text
        // Do not mutate SwiftUI state during layout/updateUIView.
        let callback=report
        let ready=bounds.width>0 && bounds.height>0 && c?.isEnabled == true && c?.isActive == true && previewLayer.isPreviewing
        DispatchQueue.main.async { callback?(text,ready) }
    }
}
private struct P3Preview:UIViewRepresentable {
    let session:AVCaptureSession
    let diagnosticRevision:Int
    let report:(String,Bool)->Void
    func makeUIView(context:Context)->P3PreviewView {
        let view=P3PreviewView()
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session=session
        view.report=report
        return view
    }
    func updateUIView(_ view:P3PreviewView,context:Context) {
        view.report=report
        view.reportDiagnostic()
    }
}
// Retained independently of SwiftUI body recomputation. The URL is supplied only
// after the human reopen command has passed Store/hash validation; no autoplay.
@MainActor
private final class P3PlaybackController:ObservableObject {
    let player=AVPlayer()
    @Published private(set) var diagnostic="Playback NOT_RUN"
    private var url:URL?
    private var errorLogCount=0
    private var lastErrorCode="none"
    private var observations:[NSKeyValueObservation]=[]
    private var notifications:[NSObjectProtocol]=[]
    func loadVerifiedLocalFile(_ url:URL) {
        guard self.url != url else { return }
        player.pause()
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
        diagnostic="Item=\(state), control=\(player.timeControlStatus.rawValue), rate=\(player.rate), time=\(seconds)s, error=\(errorCode(item.error ?? player.error)), errorLogCount=\(errorLogCount), lastErrorCode=\(lastErrorCode) — qualidade humana não aprovada"
    }
    func playByHuman() { player.play();refresh() }
    func pause() { player.pause();refresh() }
    deinit { for token in notifications { NotificationCenter.default.removeObserver(token) } }
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
    private let isRetry:Bool
    @StateObject private var controller:P3CaptureController
    init(isRetry:Bool=false) {
        self.isRetry=isRetry
        _controller=StateObject(wrappedValue:P3CaptureController(isRetry:isRetry))
    }
    @Environment(\.scenePhase) private var scene
    @State private var previewDiagnostic="Preview: não verificado"
    @State private var diagnosticRevision=0
    @State private var previewSignalReady=false
    @State private var showRetry=false
    var body:some View { ScrollView { VStack(spacing:16) {
        Text(isRetry ? "P3 — nova tentativa isolada" : "P3 mínimo — captura local").font(.title2)
        Text("Somente após coordenação: objeto neutro e contagem. Sem Photos, upload, IA ou rede.")
        Text(controller.status).accessibilityIdentifier("p3-status")
        Button("1. Preparar permissões e câmera — comando humano") { controller.prepareByHuman() }.disabled(controller.phase != .idle)
        if controller.canPreview {
            P3Preview(session:controller.session,diagnosticRevision:diagnosticRevision) {
                previewDiagnostic=$0;previewSignalReady=$1
            }.frame(height:220)
            Text(controller.previewSessionStatus)
            Text(previewDiagnostic).accessibilityIdentifier("p3-preview-diagnostic")
            Button("Atualizar diagnóstico de preview — sem gravar") {
                controller.refreshPreviewDiagnosticByHuman();diagnosticRevision += 1
            }
        }
        if isRetry {
            Text("Primeira tomada preservada. Esta tentativa não apaga nem substitui LATEST/original anterior.")
            Button("Confirmo imagem real visível no preview — comando humano") {
                controller.confirmPreviewByHuman(signalReady:previewSignalReady)
            }.disabled(!previewSignalReady || controller.phase != .ready)
        }
        Button("2. Gravar um clipe de 30 s") { controller.recordByHuman() }
            .disabled(controller.phase != .ready || (isRetry && (!previewSignalReady || !controller.previewHumanConfirmed)))
        Button("Parar antecipadamente — duração não aprovada") { controller.stopByHuman() }.disabled(![.starting,.recording].contains(controller.phase))
        Button("3. Reabrir original e habilitar Play") { controller.reopenByHuman() }.disabled(![.idle,.saved].contains(controller.phase))
        if let url=controller.playbackURL { P3PlaybackView(url:url,suspended:showRetry) }
        if !isRetry {
            Button("Abrir única nova tentativa autorizada — original preservado") { showRetry=true }
                .disabled(![.idle,.saved].contains(controller.phase))
        }
    }.padding() }.onChange(of:scene) { _,value in if value == .background { controller.suspend() } }
    .onDisappear { controller.suspend() }
    .sheet(isPresented:$showRetry) { P3CaptureScreen(isRetry:true) }
    }
}
