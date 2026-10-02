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
    guard fd>=0 else { throw P3Error.destinationExists }; defer { close(fd) }
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
    @Published private(set) var playbackURL:URL?
    let session=AVCaptureSession()
    private let q=DispatchQueue(label:"org.cevra.proof.p3.session")
    private let output=AVCaptureMovieFileOutput()
    private var state=P3State()
    private var run:URL?
    private var failure:P3Error?
    private var observers:[NSObjectProtocol]=[]
    private var startTimeout:DispatchWorkItem?
    private var watchdog:DispatchSourceTimer?
    private var configured=false
    private var audioActive=false
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
            guard !FileManager.default.fileExists(atPath:p3Base().appendingPathComponent("LATEST.json").path) else {
                self.publish("P3 já salvo — reabra sem ativar sensores; não repetir captura");return
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
        let base=p3Base();try FileManager.default.createDirectory(at:base,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
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
    func recordByHuman() { q.async { [self] in
        guard self.state.phase == .ready,self.configured,self.session.isRunning else { return }
        do {
            let base=p3Base();let free=try p3Free(base)
            guard P3Limits.mayStart(free:free,internalMic:self.internalRoute(),
                permissions:AVCaptureDevice.authorizationStatus(for:.video) == .authorized && AVCaptureDevice.authorizationStatus(for:.audio) == .authorized,
                thermalSafe:self.safeThermal()) else { throw P3Error.lowSpace }
            let dir=base.appendingPathComponent("P3-RUN-"+UUID().uuidString,isDirectory:true)
            guard mkdir(dir.path,0o700)==0 else { throw P3Error.destinationExists }
            try p3ExclusiveJSON(["protocol":"P3-MIN-001","source":"capture.mov","freeBeforeBytes":String(free)],at:dir.appendingPathComponent("capture.claim.json"))
            let file=dir.appendingPathComponent("capture.mov")
            guard !FileManager.default.fileExists(atPath:file.path),self.state.accept(.record) else { throw P3Error.destinationExists }
            self.run=dir;self.publish("STARTING — um clipe local, não repetir comando")
            self.output.startRecording(to:file,recordingDelegate:self)
            let timeout=DispatchWorkItem { [weak self] in
                guard let self,self.state.phase == .starting else { return };self.fail(.recording)
            }
            self.startTimeout=timeout;self.q.asyncAfter(deadline:.now()+5,execute:timeout)
        } catch let e as P3Error { self.fail(e) } catch { self.fail(.io) }
    } }
    func stopByHuman() { q.async {
        guard self.state.accept(.stop) else { return }
        self.publish("FINALIZING — parada solicitada; duração curta não recebe PASS")
        if self.output.isRecording { self.output.stopRecording() }
    } }
    func suspend() { q.async {
        if [.permission,.preparing,.ready,.starting,.recording].contains(self.state.phase) { self.fail(.interruption) }
    } }
    private func fail(_ error:P3Error) {
        failure=error;state.accept(.fail);startTimeout?.cancel();watchdog?.cancel();watchdog=nil
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
            guard self.state.accept(.started) else {
                if self.output.isRecording { self.output.stopRecording() }
                self.shutdown();return
            }
            self.startTimeout?.cancel();self.publish("RECORDING — parada automática em 30 s")
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
            self.startTimeout?.cancel();self.watchdog?.cancel();self.watchdog=nil
            self.shutdown()
            guard self.failure == nil,good,self.state.accept(.finished),let root=self.run else { self.fail(self.failure ?? .recording);return }
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
                    try p3ExclusiveJSON(["protocol":"P3-MIN-001","run":root.lastPathComponent],at:p3Base().appendingPathComponent("LATEST.json"))
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
                let pointer=try p3SmallJSON(p3Base().appendingPathComponent("LATEST.json"))
                guard
                      pointer["protocol"] == "P3-MIN-001",let name=pointer["run"],name.hasPrefix("P3-RUN-"),
                      let uuid=UUID(uuidString:String(name.dropFirst(7))),name == "P3-RUN-"+uuid.uuidString else { throw P3Error.integrity }
                root=p3Base().appendingPathComponent(name,isDirectory:true)
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
private struct P3Preview:UIViewRepresentable {
    let session:AVCaptureSession
    func makeUIView(context:Context)->UIView {
        let v=UIView();let layer=AVCaptureVideoPreviewLayer(session:session);layer.videoGravity = .resizeAspect
        v.layer.addSublayer(layer);return v
    }
    func updateUIView(_ view:UIView,context:Context) { view.layer.sublayers?.first?.frame=view.bounds }
}
struct P3CaptureScreen:View {
    @StateObject private var controller=P3CaptureController()
    @Environment(\.scenePhase) private var scene
    var body:some View { ScrollView { VStack(spacing:16) {
        Text("P3 mínimo — captura local").font(.title2)
        Text("Somente após coordenação: objeto neutro e contagem. Sem Photos, upload, IA ou rede.")
        Text(controller.status).accessibilityIdentifier("p3-status")
        Button("1. Preparar permissões e câmera — comando humano") { controller.prepareByHuman() }.disabled(controller.phase != .idle)
        if controller.canPreview { P3Preview(session:controller.session).frame(height:220) }
        Button("2. Gravar um clipe de 30 s") { controller.recordByHuman() }.disabled(controller.phase != .ready)
        Button("Parar antecipadamente — duração não aprovada") { controller.stopByHuman() }.disabled(![.starting,.recording].contains(controller.phase))
        Button("3. Reabrir original e habilitar Play") { controller.reopenByHuman() }.disabled(![.idle,.saved].contains(controller.phase))
        if let url=controller.playbackURL { VideoPlayer(player:AVPlayer(url:url)).frame(height:240) }
    }.padding() }.onChange(of:scene) { _,value in if value == .background { controller.suspend() } }
    .onDisappear { controller.suspend() }
    }
}
