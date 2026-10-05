import Foundation

public struct P4SyncProtocol: Codable, Sendable {
    public let formatVersion: Int
    public let protocolID: String
    public let maximumAbsoluteOffsetSeconds: Double
    public let maximumDriftSeconds: Double
}
public struct P4SyncAnnotations: Codable, Sendable {
    public let formatVersion: Int
    public let originalSHA256: String
    public let originalByteCount: Int
    public let durationSeconds: Double
    public let annotationMethod: String
    public let observations: [P4SyncObservation]
}
public struct P4SyncReport: Codable, Sendable {
    public let formatVersion: Int
    public let evidenceKind: String
    public let physicalVerification: String
    public let protocolSHA256: String
    public let annotationsSHA256: String
    public let experiment: P4SyncProtocol
    public let annotations: P4SyncAnnotations
    public let arithmetic: P4SyncMeasurement

    // Read two <=64 KiB regular files, without opening media or writing a store.
    // The caller's hash/method are declarations, not verified media/protocol timing.
    public static func make(protocolFile: URL, annotationsFile: URL) throws -> P4SyncReport {
        let configBytes = try ProofIO.boundedJSON(protocolFile)
        let annotationBytes = try ProofIO.boundedJSON(annotationsFile)
        try ProofJSON.validate(configBytes); try ProofJSON.validate(annotationBytes)
        let config = try JSONDecoder().decode(P4SyncProtocol.self, from: configBytes)
        let annotations = try JSONDecoder().decode(P4SyncAnnotations.self, from: annotationBytes)
        guard config.formatVersion == 1, annotations.formatVersion == 1 else { throw ProofError.incompatibleVersion }
        guard !config.protocolID.isEmpty, config.protocolID.utf8.count <= 80,
              config.protocolID.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) || $0 == 45 }),
              annotations.originalByteCount > 0, annotations.originalSHA256.utf8.count == 64,
              annotations.originalSHA256.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              !annotations.annotationMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              annotations.annotationMethod.utf8.count <= 512 else { throw ProofError.invalidMetadata }
        let arithmetic = try P4SyncReference.measure(annotations.observations, durationSeconds: annotations.durationSeconds,
            maximumAbsoluteOffsetSeconds: config.maximumAbsoluteOffsetSeconds, maximumDriftSeconds: config.maximumDriftSeconds)
        return P4SyncReport(formatVersion: 1, evidenceKind: "CALLER_ANNOTATED_REFERENCES",
            physicalVerification: "NOT_ESTABLISHED_BY_THIS_COMMAND", protocolSHA256: SHA256.hex(configBytes),
            annotationsSHA256: SHA256.hex(annotationBytes), experiment: config, annotations: annotations, arithmetic: arithmetic)
    }
}

// Reject duplicate object keys (including equivalent JSON escapes) and cap depth
// before Foundation decoding. Preserve input whitespace/bytes for evidence hashes.
// Foundation subsequently validates primitive syntax and typed/schema constraints.
enum ProofJSON {
    static func validate(_ data: Data) throws {
        var scanner = Scanner(bytes: Array(data))
        try scanner.value(depth: 0); scanner.whitespace()
        guard scanner.index == scanner.bytes.count else { throw ProofError.invalidMetadata }
    }
    private struct Scanner {
        let bytes: [UInt8]
        var index = 0
        mutating func whitespace() {
            while index < bytes.count, [UInt8(32), 9, 10, 13].contains(bytes[index]) { index += 1 }
        }
        mutating func accept(_ byte: UInt8) -> Bool {
            whitespace()
            guard index < bytes.count, bytes[index] == byte else { return false }
            index += 1; return true
        }
        mutating func require(_ byte: UInt8) throws {
            guard accept(byte) else { throw ProofError.invalidMetadata }
        }
        mutating func string() throws -> String {
            whitespace(); let start = index; try require(34)
            while index < bytes.count {
                if bytes[index] == 34 {
                    index += 1
                    return try JSONDecoder().decode(String.self, from: Data(bytes[start..<index]))
                }
                if bytes[index] == 92 { index += 1 }
                guard index < bytes.count else { throw ProofError.invalidMetadata }
                index += 1
            }
            throw ProofError.invalidMetadata
        }
        mutating func value(depth: Int) throws {
            whitespace()
            guard depth <= 32, index < bytes.count else { throw ProofError.invalidMetadata }
            switch bytes[index] {
            case 123:
                index += 1; var keys = Set<String>()
                if accept(125) { return }
                while true {
                    let key = try string()
                    guard keys.insert(key).inserted else { throw ProofError.invalidMetadata }
                    try require(58); try value(depth: depth + 1)
                    if accept(125) { return }; try require(44)
                }
            case 91:
                index += 1
                if accept(93) { return }
                while true {
                    try value(depth: depth + 1)
                    if accept(93) { return }; try require(44)
                }
            case 34: _ = try string()
            default:
                let start = index
                while index < bytes.count, ![UInt8(32), 9, 10, 13, 44, 93, 125].contains(bytes[index]) { index += 1 }
                guard index > start else { throw ProofError.invalidMetadata }
            }
        }
    }
}
