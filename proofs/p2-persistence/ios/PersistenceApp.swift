import SwiftUI
import Foundation
import Darwin

// Disposable physical-proof UI, not a Take application or product stack choice.
// Only the fixed synthetic P2 fixture lives in this app's own sandbox.
@main
struct PersistenceApp: App {
    var body: some Scene { WindowGroup {
        if CommandLine.arguments.contains("--p2-large-stage") { LargeProofScreen() }
        else { PersistenceProofScreen() }
    } }
}

private struct PersistenceProofScreen: View {
    @State private var status = "Nenhuma operação executada"
    @State private var details = ""

    private var base: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("P2SyntheticSandbox", isDirectory: true)
    }
    private var project: URL { base.appendingPathComponent("project", isDirectory: true) }
    private var exported: URL { base.appendingPathComponent("export", isDirectory: true) }
    private var restored: URL { base.appendingPathComponent("restored", isDirectory: true) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CEVRA Take Persistence Proof").font(.title2)
                Text("Somente fixture sintética. Sem câmera, áudio, IA ou rede.")
                Button("1. Criar e salvar R1") { perform {
                    try prepareParent()
                    try Store(project).commit(Fixture.r1, payloads: ["O": Fixture.original])
                    try check(project, expected: Fixture.r1)
                    status = "R1_SAVED_PASS"
                } }
                Button("2. Reabrir / verificar estado") { recover() }
                Button("3. Criar revisão R2") { perform {
                    // Require R1 to exist first; no silent fixture reseed on error.
                    let (before, _) = try Store(project).load()
                    guard before == Fixture.r1 || before == Fixture.r2 else { throw ProofError.invalidMetadata }
                    try Store(project).commit(Fixture.r2, payloads: ["O": Fixture.original])
                    try check(project, expected: Fixture.r2)
                    status = "R2_SAVED_T_TO_R1_PASS"
                } }
                Button("4. Exportar fixture") { perform {
                    try check(project, expected: Fixture.r2)
                    try Store(project).export(to: exported)
                    status = "EXPORT_PUBLISHED_PASS"
                } }
                Button("5. Restaurar em destino novo") { perform {
                    // 'restored' must not exist, even as an empty directory.
                    try Store(project).restore(from: exported, to: restored)
                    try check(restored, expected: Fixture.r2)
                    let source = try Store(project).load()
                    let copy = try Store(restored).load()
                    guard source.0 == copy.0, source.1 == copy.1 else { throw ProofError.invalidBundle }
                    status = "RESTORE_EQUALITY_PASS"
                } }
                Button("6. Verificar rejeição de overwrite") { perform {
                    try check(restored, expected: Fixture.r2)
                    do {
                        try Store(project).restore(from: exported, to: restored)
                        throw ProofError.invalidBundle
                    } catch ProofError.destinationExists {
                        try check(restored, expected: Fixture.r2)
                        status = "EXISTING_DESTINATION_REJECTED_PASS"
                    }
                } }
                Text(status).font(.headline).accessibilityIdentifier("p2-status")
                Text(details).font(.caption).textSelection(.enabled)
            }.padding()
        }
        .onAppear {
            if FileManager.default.fileExists(atPath: project.appendingPathComponent("CURRENT.json").path) {
                recover()
            } else {
                status = "NO_PUBLISHED_FIXTURE"
            }
        }
    }
    private func prepareParent() throws {
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
    }
    private func check(_ root: URL, expected: Snapshot) throws {
        let (snapshot, originals) = try Store(root).load()
        guard snapshot == expected, originals == ["O": Fixture.original],
              snapshot.takes.count == 1, snapshot.takes[0].revisionID == "R1"
        else { throw ProofError.invalidMetadata }
        details = "P2-FIXTURE-001 | T → R1 | revisões: \(snapshot.revisions.count)\nO: 4096 bytes\nSHA-256: \(SHA256.hex(originals["O"]!))"
    }
    private func recover() { perform {
        let (snapshot, _) = try Store(project).load()
        guard snapshot == Fixture.r1 || snapshot == Fixture.r2 else { throw ProofError.invalidMetadata }
        try check(project, expected: snapshot)
        status = snapshot == Fixture.r1 ? "R1_RECOVERED_PASS" : "R2_RECOVERED_T_TO_R1_PASS"
    } }
    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch let error as ProofError { status = "ERROR: " + error.rawValue; details = "Nenhum sucesso declarado para esta operação." }
        catch let error as POSIXError { status = "ERROR: POSIX " + String(error.code.rawValue); details = "Nenhum sucesso declarado para esta operação." }
        catch { status = "ERROR: ioOrFormat"; details = "Nenhum sucesso declarado para esta operação." }
    }
}

// Explicit launch-argument-only path; default launch never touches this directory.
private struct LargeProofScreen: View {
    @State private var status="P2_LARGE_RUNNING"
    var body: some View {
        VStack(spacing:16) {
            Text("P2 large synthetic proof").font(.title2)
            Text("Sem câmera, áudio, IA ou rede. Sandbox separado.")
            Text(status).accessibilityIdentifier("p2-large-status")
        }.padding().task {
            let args=CommandLine.arguments
            let result=await Task.detached(priority:.utility) { run(args) }.value
            status=result
        }
    }
    // Nonisolated pure entry, all expensive streaming off MainActor.
    nonisolated private func run(_ args:[String]) -> String {
        func value(_ key:String) -> String? {
            guard let i=args.firstIndex(of:key),i+1<args.count else { return nil };return args[i+1]
        }
        guard let stage=value("--p2-large-stage"),["seed","recover-roundtrip","diagnose-readonly","diagnose-seed","diagnose-roundtrip"].contains(stage),
              let run=value("--p2-large-run"), !run.isEmpty,run.count<=64,
              run.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) || $0==45 })
        else { return "ERROR: launchArguments" }
        let parent=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
            .appendingPathComponent("P2LargeSyntheticSandbox")
        let base=parent.appendingPathComponent(run)
        var result=["fixture":"P2-LARGE-001","stage":stage,"run":run,
                    "byteCount":String(LargeFixture.byteCount),"sha256":LargeFixture.hash,
                    "chunkBytes":String(Store.STREAM_CHUNK_BYTES)]
        if stage=="diagnose-readonly" {
            return diagnose(base:base,args:args,stage:stage,run:run)
        }
        if stage=="diagnose-seed" {
            return diagnoseMutating(base:base,args:args,run:run,roundtrip:false)
        }
        if stage=="diagnose-roundtrip" {
            return diagnoseMutating(base:base,args:args,run:run,roundtrip:true)
        }
        do {
            if stage=="seed" {
                try FileManager.default.createDirectory(at:parent,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
                try LargeFixture.seed(base)
                result["result"]="P2_LARGE_SEED_PASS"
            } else {
                try LargeFixture.recoverRoundtrip(base)
                result["result"]="P2_LARGE_ROUNDTRIP_PASS"
                result["sourceRemoved"]="true";result["overwriteRejected"]="true"
                result["takeRevision"]="R1";result["revisions"]="R1,R2"
            }
        } catch let e as ProofError { result["result"]="FAIL";result["error"]=e.rawValue }
        catch let e as POSIXError { result["result"]="FAIL";result["error"]="posix:"+String(e.code.rawValue) }
        catch { result["result"]="FAIL";result["error"]="ioOrFormat" }
        do {
            let output=base.appendingPathComponent(stage+"-result.json")
            let fd=open(output.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
            guard fd>=0 else { return "ERROR: resultDestination" };defer { close(fd) }
            let handle=FileHandle(fileDescriptor:fd,closeOnDealloc:false)
            try handle.write(contentsOf:try canonical(result))
            guard fsync(fd)==0 else { return "ERROR: resultSync" }
        } catch { return "ERROR: resultWrite" }
        return result["result"]!+(result["error"].map { ": "+$0 } ?? "")
    }
}

extension LargeProofScreen {
    nonisolated fileprivate func diagnose(base:URL,args:[String],stage:String,run:String) -> String {
        guard let index=args.firstIndex(of:"--p2-diagnostic-id"),index+1<args.count else { return "ERROR: diagnosticArguments" }
        let id=args[index+1]
        guard !id.isEmpty,id.count<=64,id.utf8.allSatisfy({(65...90).contains($0) || (48...57).contains($0) || $0==45}) else { return "ERROR: diagnosticArguments" }
        var isDir:ObjCBool=false
        guard FileManager.default.fileExists(atPath:base.path,isDirectory:&isDir),isDir.boolValue else { return "ERROR: diagnosticRunMissing" }
        // Reserve new output before reading. Never replace seed-result or existing evidence.
        let output=base.appendingPathComponent("diagnostic-"+id+".json")
        let fd=open(output.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
        guard fd>=0 else { return "ERROR: diagnosticDestination" };defer { close(fd) }
        var events=[[String:String]](),overflow=false
        let store=Store(base.appendingPathComponent("project"),diagnostic:{ event in
            if events.count<128 { events.append(event) } else { overflow=true }
        })
        var summary=["stage":stage,"run":run,"diagnosticID":id,"mode":"read-only-existing-store",
                     "pid":String(getpid()),"result":"P2_DIAGNOSTIC_READ_PASS"]
        do {
            let snapshot=try store.diagnoseReadOnly()
            guard snapshot==LargeFixture.snapshot() else { throw ProofError.invalidMetadata }
        } catch let e as ProofError { summary["result"]="FAIL";summary["error"]=e.rawValue }
        catch let e as POSIXError { summary["result"]="FAIL";summary["error"]="posix:"+String(e.code.rawValue) }
        catch { summary["result"]="FAIL";summary["error"]="ioOrFormat" }
        summary["traceOverflow"]=String(overflow)
        struct Report:Encodable { let summary:[String:String];let events:[[String:String]] }
        do {
            let data=try canonical(Report(summary:summary,events:events))
            guard data.count<=128*1024 else { return "ERROR: diagnosticReportLimit" }
            try FileHandle(fileDescriptor:fd,closeOnDealloc:false).write(contentsOf:data)
            guard fsync(fd)==0 else { return "ERROR: diagnosticSync" }
        } catch { return "ERROR: diagnosticWrite" }
        return summary["result"]!+(summary["error"].map { ": "+$0 } ?? "")
    }
}

extension LargeProofScreen {
    // Prepared only; execution requires the separately approved one-run causal gate.
    nonisolated fileprivate func diagnoseMutating(base:URL,args:[String],run:String,roundtrip:Bool) -> String {
        guard let index=args.firstIndex(of:"--p2-diagnostic-id"),index+1<args.count else { return "ERROR: diagnosticArguments" }
        let id=args[index+1]
        guard !id.isEmpty,id.count<=64,id.utf8.allSatisfy({(65...90).contains($0) || (48...57).contains($0) || $0==45}) else { return "ERROR: diagnosticArguments" }
        // lstat rejects any pre-existing RUN, including symlinks; no silent reseed.
        var st=stat()
        if roundtrip {
            guard run=="P2-LARGE-RUN-FIX-01",lstat(base.path,&st)==0,
                  (st.st_mode&S_IFMT)==S_IFDIR else { return "ERROR: causalRunRequired" }
        } else {
            guard lstat(base.path,&st) != 0,errno==ENOENT else { return "ERROR: existingRun" }
        }
        let parent=base.deletingLastPathComponent()
        do { try FileManager.default.createDirectory(at:parent,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700]) }
        catch { return "ERROR: diagnosticParent" }
        let prefix=roundtrip ? "roundtrip-" : "causal-"
        let output=parent.appendingPathComponent(prefix+run+"-"+id+".jsonl")
        let fd=open(output.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
        guard fd>=0 else { return "ERROR: diagnosticDestination" };defer { close(fd) }
        let handle=FileHandle(fileDescriptor:fd,closeOnDealloc:false)
        var count=0,totalBytes=0,reportError=false,phase="start"
        func emit(_ event:[String:String]) {
            guard !reportError else { return }
            do {
                var entry=event;entry["phase"]=phase
                guard count<(roundtrip ? 1024 : 256) else { reportError=true;return }
                var data=try canonical(entry);data.append(10)
                guard totalBytes+data.count<=(roundtrip ? 256 : 128)*1024 else { reportError=true;return }
                try handle.write(contentsOf:data);count+=1;totalBytes+=data.count
                // Flush phase boundaries/rejections, so interrupted diagnosis retains context.
                if event["tag"]?.hasPrefix("seed.phase.")==true || event["tag"]?.hasPrefix("roundtrip.phase.")==true || event["tag"]?.hasPrefix("reject.")==true || event["tag"]=="summary" {
                    guard fsync(fd)==0 else { reportError=true;return }
                }
            } catch { reportError=true }
        }
        emit(["tag":"start","run":run,"diagnosticID":id,"pid":String(getpid()),
              "fixture":"P2-LARGE-001","mode":roundtrip ? "roundtrip-existing-causal" : "causal-seed-explicit"])
        guard !reportError else { return "ERROR: diagnosticReportIncomplete" }
        var outcome=roundtrip ? "P2_LARGE_ROUNDTRIP_PASS" : "P2_CAUSAL_SEED_PASS",errorCode="none"
        do {
            let callback:([String:String])->Void={ event in
                if let tag=event["tag"] {
                    for prefix in ["seed.phase.","roundtrip.phase."] where tag.hasPrefix(prefix) {
                        phase=String(tag.dropFirst(prefix.count))
                    }
                }
                emit(event)
            }
            if roundtrip { try LargeFixture.recoverRoundtrip(base,diagnostic:callback) }
            else { try LargeFixture.seed(base,diagnostic:callback) }
        } catch let e as ProofError { outcome="FAIL";errorCode=e.rawValue }
        catch let e as POSIXError { outcome="FAIL";errorCode="posix:"+String(e.code.rawValue) }
        catch { outcome="FAIL";errorCode="ioOrFormat" }
        var summary=["tag":"summary","result":outcome,"error":errorCode,"phase":phase]
        if roundtrip && outcome=="P2_LARGE_ROUNDTRIP_PASS" {
            summary["sourceRemoved"]="true";summary["overwriteRejected"]="true"
            summary["byteCount"]=String(LargeFixture.byteCount);summary["sha256"]=LargeFixture.hash
            summary["takeRevision"]="R1";summary["revisions"]="R1,R2"
        }
        emit(summary)
        guard !reportError else { return "ERROR: diagnosticReportIncomplete" }
        return outcome+(errorCode=="none" ? "" : ": "+errorCode)
    }
}
