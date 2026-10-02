import Foundation

public enum ProofError: String, Error { case incompatibleVersion, invalidMetadata, missingOriginal, corruptOriginal, corruptMetadata, destinationExists, immutableHistory, unsafePath, invalidBundle, duplicate, noState }
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
        guard projectID == "P2-FIXTURE-001" else { throw ProofError.invalidMetadata }
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
