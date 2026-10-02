import Foundation
import Darwin

public enum Checkpoint: String, CaseIterable, Sendable {
    case beforeOriginalWrite, duringOriginalWrite, beforeMetadataWrite, duringMetadataWrite, beforeGenerationPublish, beforeHeadPublish, afterHeadPublish
    case exportPayloadWritten, beforeExportPublish
}
public enum FaultKind: String, Sendable { case death, denied, noSpace }
public struct Fault: Sendable {
    public let point: Checkpoint
    public let kind: FaultKind
    public init(point: Checkpoint, kind: FaultKind) { self.point=point; self.kind=kind }
    func hit(_ p: Checkpoint) throws {
        guard point == p else { return }
        switch kind {
        case .death: kill(getpid(), SIGKILL); fatalError("SIGKILL failed")
        case .denied: throw POSIXError(.EACCES)
        case .noSpace: throw POSIXError(.ENOSPC)
        }
    }
}
private struct Head: Codable { let generation: String; let metadataSHA256: String }
private struct Manifest: Codable { let formatVersion: Int; let hashes: [String: String] }

// Apple filesystem proof, not a product architecture or power-loss guarantee.
// Metadata is bounded; media is streamed. No arbitrary maximum media size.
public final class Store {
    public static let MAX_INLINE_BYTES = 16 * 1024 * 1024
    public static let STREAM_CHUNK_BYTES = 64 * 1024
    public let root: URL
    private let fm = FileManager.default
    private let diagnostic: (([String:String]) -> Void)?
    public init(_ root: URL, diagnostic: (([String:String]) -> Void)? = nil) {
        self.root=root.standardizedFileURL;self.diagnostic=diagnostic
    }
    private func trace(_ tag:String,_ values:[String:String]=[:]) {
        guard let diagnostic else { return }
        var event=values;event["tag"]=tag;diagnostic(event)
    }
    private func stats(_ st:stat) -> [String:String] {
        ["size":String(st.st_size),"mtimeSec":String(st.st_mtimespec.tv_sec),
         "mtimeNsec":String(st.st_mtimespec.tv_nsec),"ctimeSec":String(st.st_ctimespec.tv_sec),
         "ctimeNsec":String(st.st_ctimespec.tv_nsec)]
    }
    private enum Payload { case inline(Data), file(URL) }
    private func exists(_ u: URL) -> Bool {
        var st=stat(); return lstat(u.path,&st)==0
    }
    private func directory(_ u: URL) throws {
        var st=stat()
        guard lstat(u.path,&st)==0, (st.st_mode&S_IFMT)==S_IFDIR else { throw ProofError.unsafePath }
    }
    // Hold one fd for validation/read/hash/copy; never reopen between those steps.
    private func stableContentStat(_ before:stat,_ after:stat) -> Bool {
        (after.st_mode&S_IFMT)==S_IFREG && after.st_dev==before.st_dev && after.st_ino==before.st_ino &&
        after.st_size==before.st_size && after.st_mtimespec.tv_sec==before.st_mtimespec.tv_sec &&
        after.st_mtimespec.tv_nsec==before.st_mtimespec.tv_nsec
    }
    private func opened<T>(_ u: URL, contentHash:(T)->String,
                           _ body:(Int32,stat) throws -> T) throws -> T {
        let fd=open(u.standardizedFileURL.path,O_RDONLY|O_NOFOLLOW|O_NONBLOCK)
        guard fd>=0 else {
            if errno==ENOENT { throw ProofError.missingOriginal }
            throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO)
        }
        defer { close(fd) }
        trace("open",["file":u.lastPathComponent])
        var st=stat()
        guard fstat(fd,&st)==0, (st.st_mode&S_IFMT)==S_IFREG, st.st_size>=0,
              UInt64(st.st_size)<=UInt64(Int.max) else { throw ProofError.unsafePath }
        trace("fstat.before",stats(st))
        let result=try body(fd,st)
        var after=stat()
        let afterOK=fstat(fd,&after)==0
        trace("fstat.after",stats(after).merging(["ok":String(afterOK)]) { _,new in new })
        guard afterOK, stableContentStat(st,after) else {
            trace("reject.fstatChanged",["sizeEqual":String(after.st_size==st.st_size),
                "mtimeEqual":String(after.st_mtimespec.tv_sec==st.st_mtimespec.tv_sec && after.st_mtimespec.tv_nsec==st.st_mtimespec.tv_nsec),
                "ctimeEqual":String(after.st_ctimespec.tv_sec==st.st_ctimespec.tv_sec && after.st_ctimespec.tv_nsec==st.st_ctimespec.tv_nsec)])
            throw ProofError.corruptOriginal
        }
        if after.st_ctimespec.tv_sec != st.st_ctimespec.tv_sec || after.st_ctimespec.tv_nsec != st.st_ctimespec.tv_nsec {
            // ctime includes metadata changes, not just bytes. Never ignore it blindly:
            // one bounded full-content recheck on the SAME fd, without retrying writes.
            trace("metadata.ctimeChanged")
            guard lseek(fd,0,SEEK_SET)==0 else { throw POSIXError(.EIO) }
            var recheck=SHA256.Incremental()
            try consume(fd,size:Int(st.st_size)) { recheck.update($0) }
            let recheckedHash=recheck.hex(),firstHash=contentHash(result)
            trace("content.recheck",["sha256":recheckedHash,"firstSHA256":firstHash])
            guard recheckedHash==firstHash else {
                trace("reject.contentRecheckHash");throw ProofError.corruptOriginal
            }
            var final=stat()
            let finalOK=fstat(fd,&final)==0
            trace("fstat.recheck",stats(final).merging(["ok":String(finalOK)]) { _,new in new })
            guard finalOK,stableContentStat(st,final) else {
                trace("reject.contentRecheckStat");throw ProofError.corruptOriginal
            }
            trace("content.recheck.pass")
        }
        trace("read.complete",["file":u.lastPathComponent])
        return result
    }
    private func readInline(_ u:URL) throws -> Data {
        try opened(u,contentHash:{ (bytes:Data) in SHA256.hex(bytes) }) { fd,st in
            guard st.st_size<=Self.MAX_INLINE_BYTES else { throw ProofError.inlineTooLarge }
            var bytes=Data();bytes.reserveCapacity(Int(st.st_size))
            try consume(fd,size:Int(st.st_size)) { bytes.append($0) }
            return bytes
        }
    }
    private func consume(_ fd:Int32,size:Int,_ chunk:(Data) throws -> Void) throws {
        var buffer=[UInt8](repeating:0,count:Self.STREAM_CHUNK_BYTES)
        var remaining=size
        while remaining>0 {
            let requested=min(buffer.count,remaining)
            let n=buffer.withUnsafeMutableBytes { Darwin.read(fd,$0.baseAddress!,requested) }
            if n<0 { if errno==EINTR { continue };throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
            guard n>0 else {
                trace("reject.earlyEOF",["remaining":String(remaining),"expectedSize":String(size)])
                throw ProofError.corruptOriginal
            }
            try buffer.withUnsafeBytes { try chunk(Data(bytes:$0.baseAddress!,count:n)) }
            remaining-=n
        }
        var extra:UInt8=0
        var n:Int
        repeat { n=Darwin.read(fd,&extra,1) } while n<0 && errno==EINTR
        trace("consume.end",["expectedSize":String(size),"extraRead":String(n),"errno":n<0 ? String(errno) : "0"])
        guard n==0 else { trace("reject.extraByte");throw ProofError.corruptOriginal }
    }
    private func writeFD(_ data:Data,_ fd:Int32) throws {
        try data.withUnsafeBytes { b in
            var offset=0
            while offset<b.count {
                let n=Darwin.write(fd,b.baseAddress!.advanced(by:offset),b.count-offset)
                if n<0 { if errno==EINTR { continue };throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
                guard n>0 else { throw POSIXError(.EIO) };offset+=n
            }
        }
    }
    private func newFD<T>(_ u:URL,_ body:(Int32) throws -> T) throws -> T {
        let fd=open(u.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
        guard fd>=0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
        defer { close(fd) }
        let result=try body(fd)
        guard fsync(fd)==0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
        return result
    }
    private func writeNew(_ data:Data,_ u:URL,fault:Fault?=nil,checkpoint:Checkpoint?=nil) throws {
        guard data.count<=Self.MAX_INLINE_BYTES else { throw ProofError.inlineTooLarge }
        try newFD(u) { fd in
            if let checkpoint, fault?.point==checkpoint, !data.isEmpty {
                let split=max(1,data.count/2)
                try writeFD(data.prefix(split),fd);try fault?.hit(checkpoint)
                try writeFD(data.suffix(from:split),fd)
            } else { try writeFD(data,fd) }
        }
    }
    private func digest(_ source:URL,expected:Original?=nil,to destination:URL?=nil,
                        fault:Fault?=nil,checkpoint:Checkpoint?=nil) throws -> (Int,String) {
        try opened(source,contentHash:{ (value:(Int,String)) in value.1 }) { input,st in
            trace("digest.begin",["file":source.lastPathComponent,"size":String(st.st_size),"expectedSize":expected.map { String($0.byteCount) } ?? "none"])
            if let expected,Int(st.st_size) != expected.byteCount { trace("reject.digestSize");throw ProofError.corruptOriginal }
            func run(_ output:Int32?) throws -> (Int,String) {
                var hash=SHA256.Incremental();var count=0
                try consume(input,size:Int(st.st_size)) { chunk in
                    hash.update(chunk)
                    if let output { try writeFD(chunk,output) }
                    count+=chunk.count
                    if let checkpoint { try fault?.hit(checkpoint) }
                }
                let hex=hash.hex()
                trace("digest.end",["bytes":String(count),"sha256":hex,"expectedSHA256":expected?.sha256 ?? "none"])
                if let expected, hex != expected.sha256 { trace("reject.digestHash");throw ProofError.corruptOriginal }
                return (count,hex)
            }
            if let destination { return try newFD(destination) { try run($0) } }
            return try run(nil)
        }
    }
    public static func describeOriginal(id:String,source:URL,diagnostic:(([String:String])->Void)?=nil) throws -> Original {
        guard !id.isEmpty,id.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) }) else { throw ProofError.unsafePath }
        let (size,hash)=try Store(source.deletingLastPathComponent(),diagnostic:diagnostic).digest(source)
        return Original(id:id,sha256:hash,byteCount:size)
    }
    private func copy(_ payload:Payload,_ expected:Original,_ dest:URL,fault:Fault?=nil) throws {
        switch payload {
        case .file(let source): _=try digest(source,expected:expected,to:dest,fault:fault,checkpoint:.duringOriginalWrite)
        case .inline(let data): try writeNew(data,dest,fault:fault,checkpoint:.duringOriginalWrite)
        }
        guard chmod(dest.path,0o400)==0 else { throw POSIXError(.EACCES) }
    }
    private func syncDirectory(_ u:URL) throws {
        let fd=open(u.path,O_RDONLY|O_NOFOLLOW);guard fd>=0 else { throw POSIXError(.EIO) }
        defer { close(fd) };guard fsync(fd)==0 else { throw POSIXError(.EIO) }
    }
    private func publishExclusive(_ a:URL,_ b:URL) throws {
        guard renameatx_np(AT_FDCWD,a.path,AT_FDCWD,b.path,UInt32(RENAME_EXCL))==0 else {
            if errno==EEXIST || errno==ENOTEMPTY { throw ProofError.destinationExists }
            throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO)
        }
    }
    private func locked<T>(_ body:() throws -> T) throws -> T {
        if !exists(root) { try fm.createDirectory(at:root,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700]) }
        try directory(root)
        let fd=open(root.appendingPathComponent(".lock").path,O_RDWR|O_CREAT|O_NOFOLLOW,0o600)
        guard fd>=0 else { throw POSIXError(.EACCES) };defer { close(fd) }
        guard flock(fd,LOCK_EX)==0 else { throw POSIXError(.EIO) };defer { flock(fd,LOCK_UN) }
        return try body()
    }
    private func decodeSnapshot(_ bytes:Data) throws -> Snapshot {
        let s=try JSONDecoder().decode(Snapshot.self,from:bytes);try s.validate();return s
    }
    private func loadFilesUnlocked() throws -> (Snapshot,[String:URL]) {
        trace("load.CURRENT")
        let current=root.appendingPathComponent("CURRENT.json")
        guard exists(current) else { throw ProofError.noState }
        let h=try JSONDecoder().decode(Head.self,from:readInline(current))
        guard h.generation.hasPrefix("g-"),UUID(uuidString:String(h.generation.dropFirst(2))) != nil else { throw ProofError.unsafePath }
        let gens=root.appendingPathComponent("generations");try directory(gens)
        let g=gens.appendingPathComponent(h.generation);try directory(g)
        trace("load.metadata")
        let metadata=try readInline(g.appendingPathComponent("metadata.json"))
        let metadataHash=SHA256.hex(metadata)
        trace("metadata.hash",["sha256":metadataHash,"expectedSHA256":h.metadataSHA256])
        guard metadataHash==h.metadataSHA256 else { throw ProofError.corruptMetadata }
        let s=try decodeSnapshot(metadata),originals=g.appendingPathComponent("originals");try directory(originals)
        var files=[String:URL]()
        for o in s.originals {
            trace("load.original",["id":o.id])
            let file=originals.appendingPathComponent(o.id+".bin")
            _=try digest(file,expected:o);files[o.id]=file
        }
        return (s,files)
    }
    // Validated, immutable-generation references, not external source dependencies.
    public func loadFiles() throws -> (Snapshot,[String:URL]) { try locked { try loadFilesUnlocked() } }
    // Explicit diagnostic only: no lock creation, commit, staging, or repair.
    // Caller guarantees no active writer; result is not a concurrent consistency proof.
    public func diagnoseReadOnly() throws -> Snapshot {
        try directory(root);return try loadFilesUnlocked().0
    }
    private func inlineBudget(_ sizes:[Int]) throws {
        var remaining=Self.MAX_INLINE_BYTES
        for size in sizes {
            guard size>=0,size<=remaining else { throw ProofError.inlineTooLarge };remaining-=size
        }
    }
    public func load() throws -> (Snapshot,[String:Data]) {
        try locked {
            let (s,files)=try loadFilesUnlocked()
            try inlineBudget(s.originals.map(\.byteCount))
            var bytes=[String:Data]()
            for o in s.originals {
                let b=try readInline(files[o.id]!)
                guard b.count==o.byteCount,SHA256.hex(b)==o.sha256 else { throw ProofError.corruptOriginal }
                bytes[o.id]=b
            }
            return (s,bytes)
        }
    }
    public func commit(_ s:Snapshot,payloads:[String:Data],fault:Fault?=nil) throws {
        // Total retained payload, not merely per-file cap: predictable inline memory.
        try inlineBudget(Array(payloads.values.map(\.count)))
        try commit(s,payloads:payloads.mapValues { .inline($0) },fault:fault)
    }
    public func commitFiles(_ s:Snapshot,sources:[String:URL],fault:Fault?=nil) throws {
        try commit(s,payloads:sources.mapValues { .file($0) },fault:fault)
    }
    private func commit(_ s:Snapshot,payloads:[String:Payload],fault:Fault?) throws {
        try s.validate()
        guard Set(payloads.keys)==Set(s.originals.map(\.id)) else { throw ProofError.invalidMetadata }
        let metadata=try canonical(s)
        guard metadata.count<=Self.MAX_INLINE_BYTES else { throw ProofError.inlineTooLarge }
        // Validate all input before creating a store/staging; recheck same content while copying.
        for o in s.originals {
            switch payloads[o.id]! {
            case .inline(let b): guard b.count==o.byteCount,SHA256.hex(b)==o.sha256 else { throw ProofError.corruptOriginal }
            case .file(let u): _=try digest(u,expected:o)
            }
        }
        try locked {
            if exists(root.appendingPathComponent("CURRENT.json")) {
                let (old,_)=try loadFilesUnlocked()
                guard old.projectID==s.projectID,
                      old.revisions.allSatisfy({s.revisions.contains($0)}),
                      old.takes.allSatisfy({s.takes.contains($0)}),
                      old.originals.allSatisfy({s.originals.contains($0)}) else { throw ProofError.immutableHistory }
                if old==s { return }
            }
            let gens=root.appendingPathComponent("generations")
            if !exists(gens) { try fm.createDirectory(at:gens,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700]) }
            try directory(gens)
            let id=UUID().uuidString,stage=gens.appendingPathComponent(".stage-"+id)
            try fm.createDirectory(at:stage,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
            let originals=stage.appendingPathComponent("originals")
            try fm.createDirectory(at:originals,withIntermediateDirectories:false)
            try fault?.hit(.beforeOriginalWrite)
            for o in s.originals { try copy(payloads[o.id]!,o,originals.appendingPathComponent(o.id+".bin"),fault:fault) }
            try syncDirectory(originals);try fault?.hit(.beforeMetadataWrite)
            try writeNew(metadata,stage.appendingPathComponent("metadata.json"),fault:fault,checkpoint:.duringMetadataWrite)
            guard chmod(stage.appendingPathComponent("metadata.json").path,0o400)==0 else { throw POSIXError(.EACCES) }
            try syncDirectory(stage);try fault?.hit(.beforeGenerationPublish)
            let final=gens.appendingPathComponent("g-"+id)
            try publishExclusive(stage,final);try syncDirectory(gens)
            let headTemp=root.appendingPathComponent(".head-"+id)
            try writeNew(try canonical(Head(generation:final.lastPathComponent,metadataSHA256:SHA256.hex(metadata))),headTemp)
            try fault?.hit(.beforeHeadPublish)
            guard rename(headTemp.path,root.appendingPathComponent("CURRENT.json").path)==0 else { throw POSIXError(.EIO) }
            try syncDirectory(root);try fault?.hit(.afterHeadPublish)
        }
    }
    public func export(to destination:URL,fault:Fault?=nil) throws {
        guard !exists(destination) else { throw ProofError.destinationExists }
        try locked {
            let (s,files)=try loadFilesUnlocked(),metadata=try canonical(s)
            var hashes=["metadata.json":SHA256.hex(metadata)]
            for o in s.originals { hashes["originals/"+o.id+".bin"]=o.sha256 }
            let manifest=try canonical(Manifest(formatVersion:1,hashes:hashes))
            guard metadata.count<=Self.MAX_INLINE_BYTES,manifest.count<=Self.MAX_INLINE_BYTES else { throw ProofError.inlineTooLarge }
            let stage=destination.deletingLastPathComponent().appendingPathComponent(".export-"+UUID().uuidString)
            try fm.createDirectory(at:stage,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
            let originals=stage.appendingPathComponent("originals")
            try fm.createDirectory(at:originals,withIntermediateDirectories:false)
            try writeNew(metadata,stage.appendingPathComponent("metadata.json"))
            for o in s.originals { _=try digest(files[o.id]!,expected:o,to:originals.appendingPathComponent(o.id+".bin")) }
            try fault?.hit(.exportPayloadWritten)
            try writeNew(manifest,stage.appendingPathComponent("manifest.json"))
            try syncDirectory(originals);try syncDirectory(stage);_=try validateBundle(stage)
            try fault?.hit(.beforeExportPublish)
            try publishExclusive(stage,destination);try syncDirectory(destination.deletingLastPathComponent())
        }
    }
    private func validateBundle(_ bundle:URL) throws -> (Snapshot,[String:URL]) {
        trace("bundle.begin")
        try directory(bundle)
        let manifest=try JSONDecoder().decode(Manifest.self,from:readInline(bundle.appendingPathComponent("manifest.json")))
        guard manifest.formatVersion==1 else { throw ProofError.incompatibleVersion }
        let metadata=try readInline(bundle.appendingPathComponent("metadata.json"))
        let s=try decodeSnapshot(metadata)
        let expected=Set(["metadata.json"]+s.originals.map { "originals/"+$0.id+".bin" })
        guard Set(manifest.hashes.keys)==expected else { throw ProofError.invalidBundle }
        let hash=SHA256.hex(metadata)
        trace("bundle.metadata.hash",["sha256":hash,"expectedSHA256":manifest.hashes["metadata.json"] ?? "missing"])
        guard manifest.hashes["metadata.json"]==hash else { throw ProofError.corruptMetadata }
        guard Set(try fm.contentsOfDirectory(atPath:bundle.path))==["metadata.json","manifest.json","originals"] else { throw ProofError.invalidBundle }
        let dir=bundle.appendingPathComponent("originals");try directory(dir)
        var files=[String:URL]()
        for o in s.originals {
            let file=dir.appendingPathComponent(o.id+".bin")
            trace("bundle.original",["id":o.id])
            guard manifest.hashes["originals/"+o.id+".bin"]==o.sha256 else { trace("reject.manifestOriginalHash");throw ProofError.corruptOriginal }
            _=try digest(file,expected:o);files[o.id]=file
        }
        guard Set(try fm.contentsOfDirectory(atPath:dir.path))==Set(s.originals.map { $0.id+".bin" }) else { throw ProofError.invalidBundle }
        return (s,files)
    }
    public func restore(from bundle:URL,to destination:URL) throws {
        guard !exists(destination) else { throw ProofError.destinationExists }
        trace("restore.validateInput")
        let (s,files)=try validateBundle(bundle)
        let stage=destination.deletingLastPathComponent().appendingPathComponent(".restore-"+UUID().uuidString)
        let staged=Store(stage,diagnostic:diagnostic)
        trace("restore.commitStage")
        try staged.commitFiles(s,sources:files)
        trace("restore.verifyStage")
        let (verified,_)=try staged.loadFiles()
        guard verified==s else { throw ProofError.invalidBundle }
        trace("restore.publish")
        try publishExclusive(stage,destination);try syncDirectory(destination.deletingLastPathComponent())
    }
}
