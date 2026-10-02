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

// Host filesystem adapter: Foundation + Apple Darwin POSIX APIs only.
// Single-writer flock, immutable generations, fsync and atomic publication.
// This is not an iOS lifecycle or power-loss guarantee.
public final class Store {
    public let root: URL
    private let fm=FileManager.default
    public init(_ root: URL) { self.root=root.standardizedFileURL }
    private func exists(_ u: URL) -> Bool {
        var st=stat(); return lstat(u.path, &st) == 0
    }
    private func directory(_ u: URL) throws {
        var st=stat()
        guard lstat(u.path,&st)==0, (st.st_mode & S_IFMT)==S_IFDIR else { throw ProofError.unsafePath }
    }
    private func read(_ u: URL) throws -> Data {
        let fd=open(u.path,O_RDONLY|O_NOFOLLOW)
        guard fd>=0 else {
            if errno==ENOENT { throw ProofError.missingOriginal }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer { close(fd) }
        var st=stat()
        guard fstat(fd,&st)==0, (st.st_mode&S_IFMT)==S_IFREG, st.st_size<=16*1024*1024 else { throw ProofError.unsafePath }
        let handle=FileHandle(fileDescriptor:fd,closeOnDealloc:false)
        return try handle.readToEnd() ?? Data()
    }
    private func writeNew(_ data: Data, _ u: URL, fault: Fault? = nil, checkpoint: Checkpoint? = nil) throws {
        let fd=open(u.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
        guard fd>=0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
        defer { close(fd) }
        try data.withUnsafeBytes { buf in
            var offset=0
            while offset<buf.count {
                let requested = (offset == 0 && checkpoint != nil && fault?.point == checkpoint) ? max(1,buf.count/2) : buf.count-offset
                let n=Darwin.write(fd,buf.baseAddress!.advanced(by:offset),requested)
                if n<0 { if errno==EINTR { continue }; throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
                guard n>0 else { throw POSIXError(.EIO) }
                offset+=n
                if let checkpoint { try fault?.hit(checkpoint) }
            }
        }
        guard fsync(fd)==0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
    }
    private func syncDirectory(_ u: URL) throws {
        let fd=open(u.path,O_RDONLY|O_NOFOLLOW)
        guard fd>=0 else { throw POSIXError(.EIO) }
        defer { close(fd) }
        guard fsync(fd)==0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
    }
    private func publishExclusive(_ a: URL, _ b: URL) throws {
        guard renameatx_np(AT_FDCWD,a.path,AT_FDCWD,b.path,UInt32(RENAME_EXCL))==0 else {
            if errno==EEXIST || errno==ENOTEMPTY { throw ProofError.destinationExists }
            throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO)
        }
    }
    private func locked<T>(_ body: () throws -> T) throws -> T {
        if !exists(root) { try fm.createDirectory(at:root,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700]) }
        try directory(root)
        let fd=open(root.appendingPathComponent(".lock").path,O_RDWR|O_CREAT|O_NOFOLLOW,0o600)
        guard fd>=0 else { throw POSIXError(.EACCES) }
        defer { close(fd) }
        guard flock(fd,LOCK_EX)==0 else { throw POSIXError(.EIO) }
        defer { flock(fd,LOCK_UN) }
        return try body()
    }
    private func decodeSnapshot(_ bytes: Data) throws -> Snapshot {
        let s=try JSONDecoder().decode(Snapshot.self,from:bytes)
        try s.validate(); return s
    }
    private func loadUnlocked() throws -> (Snapshot, [String:Data]) {
        let current=root.appendingPathComponent("CURRENT.json")
        guard exists(current) else { throw ProofError.noState }
        let h=try JSONDecoder().decode(Head.self,from:read(current))
        guard h.generation.hasPrefix("g-"), UUID(uuidString:String(h.generation.dropFirst(2))) != nil else { throw ProofError.unsafePath }
        let gens=root.appendingPathComponent("generations");try directory(gens)
        let g=gens.appendingPathComponent(h.generation);try directory(g)
        let metadata=try read(g.appendingPathComponent("metadata.json"))
        guard SHA256.hex(metadata)==h.metadataSHA256 else { throw ProofError.corruptMetadata }
        let s=try decodeSnapshot(metadata)
        let originals=g.appendingPathComponent("originals");try directory(originals)
        var payloads=[String:Data]()
        for o in s.originals {
            let b=try read(originals.appendingPathComponent(o.id+".bin"))
            guard b.count==o.byteCount, SHA256.hex(b)==o.sha256 else { throw ProofError.corruptOriginal }
            payloads[o.id]=b
        }
        return (s,payloads)
    }
    public func load() throws -> (Snapshot, [String:Data]) { try locked { try loadUnlocked() } }
    public func commit(_ s: Snapshot, payloads: [String:Data], fault: Fault? = nil) throws {
        try s.validate()
        guard Set(payloads.keys)==Set(s.originals.map(\.id)) else { throw ProofError.invalidMetadata }
        for o in s.originals {
            guard let b=payloads[o.id], b.count==o.byteCount, SHA256.hex(b)==o.sha256 else { throw ProofError.corruptOriginal }
        }
        try locked {
            if exists(root.appendingPathComponent("CURRENT.json")) {
                let (old,oldBytes)=try loadUnlocked()
                guard old.projectID==s.projectID,
                      old.revisions.allSatisfy({ s.revisions.contains($0) }),
                      old.takes.allSatisfy({ s.takes.contains($0) }),
                      old.originals.allSatisfy({ s.originals.contains($0) }),
                      oldBytes.allSatisfy({ payloads[$0.key]==$0.value }) else { throw ProofError.immutableHistory }
                if old==s { return } // Idempotent retry: no duplicate revision/generation.
            }
            let gens=root.appendingPathComponent("generations")
            if !exists(gens) { try fm.createDirectory(at:gens,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700]) }
            try directory(gens)
            let id=UUID().uuidString
            let stage=gens.appendingPathComponent(".stage-"+id)
            try fm.createDirectory(at:stage,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
            let originals=stage.appendingPathComponent("originals")
            try fm.createDirectory(at:originals,withIntermediateDirectories:false)
            try fault?.hit(.beforeOriginalWrite)
            for o in s.originals {
                let file=originals.appendingPathComponent(o.id+".bin")
                try writeNew(payloads[o.id]!,file,fault:fault,checkpoint:.duringOriginalWrite)
                guard chmod(file.path,0o400)==0 else { throw POSIXError(.EACCES) }
            }
            try syncDirectory(originals)
            try fault?.hit(.beforeMetadataWrite)
            let metadata=try canonical(s)
            try writeNew(metadata,stage.appendingPathComponent("metadata.json"),fault:fault,checkpoint:.duringMetadataWrite)
            guard chmod(stage.appendingPathComponent("metadata.json").path,0o400)==0 else { throw POSIXError(.EACCES) }
            try syncDirectory(stage)
            try fault?.hit(.beforeGenerationPublish)
            let final=gens.appendingPathComponent("g-"+id)
            try publishExclusive(stage,final);try syncDirectory(gens)
            let headTemp=root.appendingPathComponent(".head-"+id)
            try writeNew(try canonical(Head(generation:final.lastPathComponent,metadataSHA256:SHA256.hex(metadata))),headTemp)
            try fault?.hit(.beforeHeadPublish)
            guard rename(headTemp.path,root.appendingPathComponent("CURRENT.json").path)==0 else { throw POSIXError(.EIO) }
            try syncDirectory(root)
            try fault?.hit(.afterHeadPublish)
        }
    }
    public func export(to destination: URL, fault: Fault? = nil) throws {
        guard !exists(destination) else { throw ProofError.destinationExists }
        let (s,payloads)=try load()
        let stage=destination.deletingLastPathComponent().appendingPathComponent(".export-"+UUID().uuidString)
        try fm.createDirectory(at:stage,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
        let originals=stage.appendingPathComponent("originals")
        try fm.createDirectory(at:originals,withIntermediateDirectories:false)
        let metadata=try canonical(s)
        try writeNew(metadata,stage.appendingPathComponent("metadata.json"))
        var hashes=["metadata.json":SHA256.hex(metadata)]
        for o in s.originals {
            let b=payloads[o.id]!
            try writeNew(b,originals.appendingPathComponent(o.id+".bin"))
            hashes["originals/"+o.id+".bin"]=o.sha256
        }
        try fault?.hit(.exportPayloadWritten)
        try writeNew(try canonical(Manifest(formatVersion:1,hashes:hashes)),stage.appendingPathComponent("manifest.json"))
        try syncDirectory(originals);try syncDirectory(stage)
        _=try validateBundle(stage)
        try fault?.hit(.beforeExportPublish)
        try publishExclusive(stage,destination)
        try syncDirectory(destination.deletingLastPathComponent())
    }
    private func validateBundle(_ bundle: URL) throws -> (Snapshot,[String:Data]) {
        try directory(bundle)
        let manifest=try JSONDecoder().decode(Manifest.self,from:read(bundle.appendingPathComponent("manifest.json")))
        guard manifest.formatVersion==1 else { throw ProofError.incompatibleVersion }
        let metadata=try read(bundle.appendingPathComponent("metadata.json"))
        // Version is diagnosed before hashes; incompatible formats are never rewritten.
        let s=try decodeSnapshot(metadata)
        let expected=Set(["metadata.json"]+s.originals.map { "originals/"+$0.id+".bin" })
        guard Set(manifest.hashes.keys)==expected else { throw ProofError.invalidBundle }
        guard manifest.hashes["metadata.json"]==SHA256.hex(metadata) else { throw ProofError.corruptMetadata }
        guard Set(try fm.contentsOfDirectory(atPath:bundle.path))==["metadata.json","manifest.json","originals"] else { throw ProofError.invalidBundle }
        let dir=bundle.appendingPathComponent("originals");try directory(dir)
        var bytes=[String:Data]()
        for o in s.originals {
            let b=try read(dir.appendingPathComponent(o.id+".bin"))
            guard b.count==o.byteCount, SHA256.hex(b)==o.sha256, manifest.hashes["originals/"+o.id+".bin"]==o.sha256 else { throw ProofError.corruptOriginal }
            bytes[o.id]=b
        }
        guard Set(try fm.contentsOfDirectory(atPath:dir.path))==Set(s.originals.map { $0.id+".bin" }) else { throw ProofError.invalidBundle }
        return (s,bytes)
    }
    public func restore(from bundle: URL, to destination: URL) throws {
        guard !exists(destination) else { throw ProofError.destinationExists }
        let (s,bytes)=try validateBundle(bundle)
        let stage=destination.deletingLastPathComponent().appendingPathComponent(".restore-"+UUID().uuidString)
        let staged=Store(stage)
        try staged.commit(s,payloads:bytes)
        let (verified,verifiedBytes)=try staged.load()
        guard verified==s,verifiedBytes==bytes else { throw ProofError.invalidBundle }
        try publishExclusive(stage,destination)
        try syncDirectory(destination.deletingLastPathComponent())
    }
}
