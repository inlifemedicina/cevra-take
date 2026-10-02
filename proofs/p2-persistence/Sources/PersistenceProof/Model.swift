import Foundation
import Darwin

public enum ProofError: String, Error { case inlineTooLarge, incompatibleVersion, invalidMetadata, missingOriginal, corruptOriginal, corruptMetadata, destinationExists, immutableHistory, unsafePath, invalidBundle, duplicate, noState }
public struct Revision: Codable, Equatable, Sendable {
    public let id: String
    public let scriptID: String
    public let text: String
}
public struct Take: Codable, Equatable, Sendable {
    public let id: String
    public let revisionID: String
    public let originalID: String
    public let synthetic: Bool
}
public struct Original: Codable, Equatable, Sendable {
    public let id: String
    public let sha256: String
    public let byteCount: Int
}
public struct Snapshot: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public let projectID: String
    public var revisions: [Revision]
    public var takes: [Take]
    public var originals: [Original]
    public func validate() throws {
        guard formatVersion == 1 else { throw ProofError.incompatibleVersion }
        guard projectID == "P2-FIXTURE-001" || projectID == "P2-LARGE-001" else { throw ProofError.invalidMetadata }
        for ids in [revisions.map(\.id), takes.map(\.id), originals.map(\.id)] {
            guard Set(ids).count == ids.count else { throw ProofError.duplicate }
            guard ids.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (65...90).contains($0) || (48...57).contains($0) } }) else { throw ProofError.unsafePath }
        }
        guard !revisions.isEmpty,
              revisions.allSatisfy({ $0.scriptID == "S" }),
              takes.allSatisfy({ t in t.synthetic && revisions.contains { $0.id == t.revisionID } && originals.contains { $0.id == t.originalID } }),
              originals.allSatisfy({ $0.byteCount >= 0 && $0.sha256.count == 64 && $0.sha256.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) } })
        else { throw ProofError.invalidMetadata }
    }
}
public enum Fixture {
    public static let original = Data((0..<4096).map { UInt8(($0 * 17 + 3) % 256) })
    public static var r1: Snapshot {
        Snapshot(formatVersion: 1, projectID: "P2-FIXTURE-001",
                 revisions: [Revision(id: "R1", scriptID: "S", text: "Roteiro fictício P2: preparar, salvar e reabrir.")],
                 takes: [Take(id: "T", revisionID: "R1", originalID: "O", synthetic: true)],
                 originals: [Original(id: "O", sha256: SHA256.hex(original), byteCount: original.count)])
    }
    public static var r2: Snapshot {
        var s=r1
        s.revisions.append(Revision(id: "R2", scriptID: "S", text: "Roteiro fictício P2: revisão posterior, procedência preservada."))
        return s
    }
}
public func canonical<T: Encodable>(_ value: T) throws -> Data {
    let e=JSONEncoder(); e.outputFormatting=[.sortedKeys, .withoutEscapingSlashes]
    return try e.encode(value)
}

// Separate fixed synthetic file fixture. No media access or arbitrary input generator.
public enum LargeFixture {
    public static let byteCount=32*1024*1024+4096
    public static let hash="57b8d6a829e70202a5510092acdf47119ca9a803c5b8c5ca697b41a28bdc14d2"
    public static func snapshot(r2:Bool=false) -> Snapshot {
        var s=Fixture.r1
        s=Snapshot(formatVersion:1,projectID:"P2-LARGE-001",revisions:s.revisions,
                   takes:s.takes,originals:[Original(id:"O",sha256:hash,byteCount:byteCount)])
        if r2 { s.revisions.append(Fixture.r2.revisions[1]) }
        return s
    }
    public static func generate(at file:URL) throws {
        let fd=open(file.path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0o600)
        guard fd>=0 else { throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
        defer { close(fd) }
        let chunk=Data((0..<Store.STREAM_CHUNK_BYTES).map { UInt8(($0*17+3)%256) })
        var remaining=byteCount
        while remaining>0 {
            let count=min(chunk.count,remaining)
            try chunk.withUnsafeBytes { bytes in
                var offset=0
                while offset<count {
                    let n=Darwin.write(fd,bytes.baseAddress!.advanced(by:offset),count-offset)
                    if n<0 { if errno==EINTR { continue };throw POSIXError(POSIXErrorCode(rawValue:errno) ?? .EIO) }
                    guard n>0 else { throw POSIXError(.EIO) };offset+=n
                }
            }
            remaining-=count
        }
        guard fsync(fd)==0 else { throw POSIXError(.EIO) }
    }
    public static func verify(_ root:URL,expected:Snapshot,diagnostic:(([String:String])->Void)?=nil) throws {
        let (s,_)=try Store(root,diagnostic:diagnostic).loadFiles()
        guard s==expected,s.takes.count==1,s.takes[0].revisionID=="R1",
              s.originals[0].byteCount==byteCount,s.originals[0].sha256==hash else { throw ProofError.invalidMetadata }
    }
    public static func seed(_ base:URL,diagnostic:(([String:String])->Void)?=nil) throws {
        guard !FileManager.default.fileExists(atPath:base.path) else { throw ProofError.destinationExists }
        try FileManager.default.createDirectory(at:base,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
        let source=base.appendingPathComponent("synthetic-source.bin")
        diagnostic?(["tag":"seed.phase.generate"])
        try generate(at:source)
        diagnostic?(["tag":"seed.phase.describe"])
        let described=try Store.describeOriginal(id:"O",source:source,diagnostic:diagnostic)
        guard described==snapshot().originals[0] else {
            diagnostic?(["tag":"reject.fixtureDescriptor"]);throw ProofError.corruptOriginal
        }
        diagnostic?(["tag":"seed.phase.commit"])
        try Store(base.appendingPathComponent("project"),diagnostic:diagnostic).commitFiles(snapshot(),sources:["O":source])
        diagnostic?(["tag":"seed.phase.postcommit"])
        try verify(base.appendingPathComponent("project"),expected:snapshot(),diagnostic:diagnostic)
        diagnostic?(["tag":"seed.complete"])
    }
    public static func recoverRoundtrip(_ base:URL,diagnostic:(([String:String])->Void)?=nil) throws {
        let project=base.appendingPathComponent("project"),source=base.appendingPathComponent("synthetic-source.bin")
        let exported=base.appendingPathComponent("export"),restored=base.appendingPathComponent("restored")
        let store=Store(project,diagnostic:diagnostic)
        // Separate invocation/process: verify R1 first; never reseed missing/corrupt data.
        diagnostic?(["tag":"roundtrip.phase.recoverR1"])
        try verify(project,expected:snapshot(),diagnostic:diagnostic)
        let (_,files)=try store.loadFiles()
        diagnostic?(["tag":"roundtrip.phase.commitR2"])
        try store.commitFiles(snapshot(r2:true),sources:files)
        diagnostic?(["tag":"roundtrip.phase.postcommitR2"])
        try verify(project,expected:snapshot(r2:true),diagnostic:diagnostic)
        diagnostic?(["tag":"roundtrip.phase.export"])
        try store.export(to:exported)
        diagnostic?(["tag":"roundtrip.phase.sourceRemoval"])
        try FileManager.default.removeItem(at:source)
        diagnostic?(["tag":"roundtrip.phase.restore"])
        try store.restore(from:exported,to:restored)
        diagnostic?(["tag":"roundtrip.phase.verifyRestored"])
        try verify(restored,expected:snapshot(r2:true),diagnostic:diagnostic)
        diagnostic?(["tag":"roundtrip.phase.overwriteGuard"])
        do {
            try store.restore(from:exported,to:restored)
            throw ProofError.invalidBundle
        } catch ProofError.destinationExists {
            diagnostic?(["tag":"overwrite.expectedRejection"])
            try verify(restored,expected:snapshot(r2:true),diagnostic:diagnostic)
            try verify(project,expected:snapshot(r2:true),diagnostic:diagnostic)
        }
        diagnostic?(["tag":"roundtrip.complete"])
    }
}
