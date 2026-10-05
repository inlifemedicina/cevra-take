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
