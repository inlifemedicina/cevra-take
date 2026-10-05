import Foundation
import Darwin

// Proof-only, uncompressed USTAR subset. Reuses Store's v1 bundle validation;
// neither a product format decision nor a general-purpose archive extractor.
public enum PortableProof {
    public static let maximumArchiveBytes = 8 * 1024 * 1024 * 1024 - 1
    public static let maximumEntries = 1024

    public static func export(_ store: Store, to destination: URL, fault: Fault? = nil) throws {
        try ProofIO.requireAbsent(destination)
        let work = try ProofIO.workspace(beside: destination)
        defer { try? FileManager.default.removeItem(at: work) }
        let bundle = work.appendingPathComponent("bundle"), archive = work.appendingPathComponent("archive.tar")
        try store.export(to: bundle)
        let names = ["metadata.json", "manifest.json"] + (try FileManager.default.contentsOfDirectory(atPath: bundle.appendingPathComponent("originals").path)).sorted().map { "originals/" + $0 }
        guard names.count <= maximumEntries else { throw ProofError.invalidBundle }
        try ProofIO.createFile(archive) { output in
            var total = 1024
            for name in names {
                guard allowed(name) else { throw ProofError.invalidBundle }
                try ProofIO.regular(bundle.appendingPathComponent(name)) { input, size in
                    guard size <= maximumArchiveBytes - total - 512 else { throw ProofError.invalidBundle }
                    let padding = (512 - size % 512) % 512
                    guard padding <= maximumArchiveBytes - total - 512 - size else { throw ProofError.invalidBundle }
                    total += 512 + size + padding
                    try ProofIO.write(header(name, size: size), to: output)
                    try ProofIO.copy(input, bytes: size, to: output) { try fault?.hit(.exportPayloadWritten) }
                    try ProofIO.write(Data(repeating: 0, count: padding), to: output)
                }
            }
            try ProofIO.write(Data(repeating: 0, count: 1024), to: output)
        }
        try fault?.hit(.beforeExportPublish)
        try ProofIO.publish(archive, to: destination)
    }

    public static func restore(from archive: URL, to destination: URL) throws {
        try ProofIO.requireAbsent(destination)
        let work = try ProofIO.workspace(beside: destination)
        defer { try? FileManager.default.removeItem(at: work) }
        let bundle = work.appendingPathComponent("bundle"), restored = work.appendingPathComponent("restored")
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try FileManager.default.createDirectory(at: bundle.appendingPathComponent("originals"), withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try ProofIO.regular(archive) { input, size in
            guard size >= 1024, size <= maximumArchiveBytes, size % 512 == 0 else { throw ProofError.invalidBundle }
            var remaining = size, names = Set<String>(), ended = false
            while remaining >= 512 {
                let block = try ProofIO.read(input, bytes: 512); remaining -= 512
                if block.allSatisfy({ $0 == 0 }) {
                    guard remaining >= 512, try ProofIO.read(input, bytes: 512).allSatisfy({ $0 == 0 }) else { throw ProofError.invalidBundle }
                    remaining -= 512
                    while remaining > 0 {
                        let count = min(remaining, Store.STREAM_CHUNK_BYTES)
                        guard try ProofIO.read(input, bytes: count).allSatisfy({ $0 == 0 }) else { throw ProofError.invalidBundle }
                        remaining -= count
                    }
                    ended = true; break
                }
                let (name, count) = try parse(block)
                guard names.count < maximumEntries, names.insert(name).inserted else { throw ProofError.invalidBundle }
                let padding = (512 - count % 512) % 512
                guard count <= remaining, padding <= remaining - count else { throw ProofError.invalidBundle }
                if name == "metadata.json" || name == "manifest.json" {
                    guard count <= Store.MAX_INLINE_BYTES else { throw ProofError.inlineTooLarge }
                }
                try ProofIO.createFile(bundle.appendingPathComponent(name)) { try ProofIO.copy(input, bytes: count, to: $0) }
                guard try ProofIO.read(input, bytes: padding).allSatisfy({ $0 == 0 }) else { throw ProofError.invalidBundle }
                remaining -= count + padding
            }
            guard ended, names.contains("metadata.json"), names.contains("manifest.json") else { throw ProofError.invalidBundle }
        }
        for control in ["metadata.json", "manifest.json"] {
            try ProofJSON.validate(ProofIO.boundedJSON(bundle.appendingPathComponent(control), limit: Store.MAX_INLINE_BYTES))
        }
        // Exact names, metadata/schema, original sizes/hashes and references are
        // validated by the existing Store before the outer destination is published.
        try Store(work).restore(from: bundle, to: restored)
        try ProofIO.publish(restored, to: destination)
    }

    private static func allowed(_ name: String) -> Bool {
        if name == "metadata.json" || name == "manifest.json" { return true }
        guard name.hasPrefix("originals/"), name.hasSuffix(".bin") else { return false }
        let id = name.dropFirst(10).dropLast(4)
        return !id.isEmpty && id.utf8.count <= 64 && id.utf8.allSatisfy { (65...90).contains($0) || (48...57).contains($0) }
    }
    private static func octal(_ n: Int, width: Int) -> [UInt8] {
        let s = String(n, radix: 8)
        return Array((String(repeating: "0", count: width - 1 - s.count) + s).utf8) + [0]
    }
    // Layout/checksum defined in GNU tar's "Basic Tar Format" documentation.
    // No third-party implementation copied; write only regular files, no IDs/paths
    // or timestamps from the user's filesystem in the archive headers.
    static func header(_ name: String, size: Int) -> Data {
        var b = [UInt8](repeating: 0, count: 512)
        func put(_ at: Int, _ bytes: [UInt8]) { b.replaceSubrange(at..<(at + bytes.count), with: bytes) }
        put(0, Array(name.utf8)); put(100, octal(0o600, width: 8))
        put(108, octal(0, width: 8)); put(116, octal(0, width: 8))
        put(124, octal(size, width: 12)); put(136, octal(0, width: 12))
        put(148, Array(repeating: 32, count: 8)); b[156] = 48
        put(257, Array("ustar".utf8) + [0]); put(263, Array("00".utf8))
        let checksum = b.reduce(0) { $0 + Int($1) }
        put(148, octal(checksum, width: 7) + [32])
        return Data(b)
    }
    private static func number(_ bytes: ArraySlice<UInt8>) throws -> Int {
        let digits = bytes.drop(while: { $0 == 32 }).prefix(while: { (48...55).contains($0) })
        guard !digits.isEmpty, bytes.dropFirst(bytes.count - bytes.drop(while: { $0 == 32 }).count + digits.count).allSatisfy({ $0 == 0 || $0 == 32 }),
              let n = Int(String(decoding: digits, as: UTF8.self), radix: 8) else { throw ProofError.invalidBundle }
        return n
    }
    private static func parse(_ data: Data) throws -> (String, Int) {
        var b = [UInt8](data)
        let expected = try number(b[148..<156])
        b.replaceSubrange(148..<156, with: repeatElement(UInt8(32), count: 8))
        guard b.reduce(0, { $0 + Int($1) }) == expected,
              b[156] == 0 || b[156] == 48,
              Array(b[257..<263]) == Array("ustar".utf8) + [0],
              Array(b[263..<265]) == Array("00".utf8),
              b[157..<257].allSatisfy({ $0 == 0 }), b[345..<512].allSatisfy({ $0 == 0 }) else { throw ProofError.invalidBundle }
        let nameBytes = b[0..<100].prefix(while: { $0 != 0 })
        guard b[nameBytes.count..<100].allSatisfy({ $0 == 0 }), nameBytes.allSatisfy({ $0 < 128 }) else { throw ProofError.invalidBundle }
        let name = String(decoding: nameBytes, as: UTF8.self)
        guard allowed(name) else { throw ProofError.invalidBundle }
        return (name, try number(b[124..<136]))
    }
}

// Local, quiescent proof files. Ancestor directories must be trusted; this is not
// isolation against an adversarial process changing path components concurrently.
enum ProofIO {
    static func requireAbsent(_ u: URL) throws {
        var st = stat()
        if lstat(u.path, &st) == 0 { throw ProofError.destinationExists }
        guard errno == ENOENT else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }
    static func workspace(beside u: URL) throws -> URL {
        let parent = u.deletingLastPathComponent()
        var st = stat()
        guard lstat(parent.path, &st) == 0, st.st_mode & S_IFMT == S_IFDIR else { throw ProofError.unsafePath }
        let work = parent.appendingPathComponent(".portable-proof-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        return work
    }
    static func regular<T>(_ u: URL, _ body: (Int32, Int) throws -> T) throws -> T {
        let fd = open(u.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(fd) }
        var before = stat(), after = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG,
              before.st_size >= 0, UInt64(before.st_size) <= UInt64(Int.max) else { throw ProofError.unsafePath }
        let result = try body(fd, Int(before.st_size))
        guard try read(fd, bytes: 1, allowEOF: true).isEmpty,
              fstat(fd, &after) == 0, before.st_dev == after.st_dev, before.st_ino == after.st_ino,
              before.st_size == after.st_size, before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
              before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec,
              before.st_ctimespec.tv_sec == after.st_ctimespec.tv_sec,
              before.st_ctimespec.tv_nsec == after.st_ctimespec.tv_nsec else { throw ProofError.invalidBundle }
        return result
    }
    static func read(_ fd: Int32, bytes: Int, allowEOF: Bool = false) throws -> Data {
        var data = Data(count: bytes), offset = 0
        while offset < bytes {
            let n = data.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress!.advanced(by: offset), bytes - offset) }
            if n < 0 { if errno == EINTR { continue }; throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
            if n == 0, allowEOF, offset == 0 { return Data() }
            guard n > 0 else { throw ProofError.invalidBundle }; offset += n
        }
        return data
    }
    static func write(_ data: Data, to fd: Int32) throws {
        try data.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                let n = Darwin.write(fd, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                if n < 0 { if errno == EINTR { continue }; throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
                guard n > 0 else { throw POSIXError(.EIO) }; offset += n
            }
        }
    }
    static func copy(_ input: Int32, bytes: Int, to output: Int32, afterChunk: () throws -> Void = {}) throws {
        var remaining = bytes
        while remaining > 0 {
            let count = min(remaining, Store.STREAM_CHUNK_BYTES)
            try write(read(input, bytes: count), to: output); remaining -= count
            try afterChunk()
        }
    }
    static func createFile<T>(_ u: URL, _ body: (Int32) throws -> T) throws -> T {
        let fd = open(u.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(fd) }
        let result = try body(fd)
        guard fsync(fd) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return result
    }
    static func publish(_ staged: URL, to destination: URL) throws {
        guard renameatx_np(AT_FDCWD, staged.path, AT_FDCWD, destination.path, UInt32(RENAME_EXCL)) == 0 else {
            if errno == EEXIST || errno == ENOTEMPTY { throw ProofError.destinationExists }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        let fd = open(destination.deletingLastPathComponent().path, O_RDONLY | O_NOFOLLOW)
        guard fd >= 0 else { throw POSIXError(.EIO) }
        defer { close(fd) }
        guard fsync(fd) == 0 else { throw POSIXError(.EIO) }
    }
    static func boundedJSON(_ u: URL, limit: Int = Store.STREAM_CHUNK_BYTES) throws -> Data {
        try regular(u) { fd, size in
            guard size <= limit else { throw ProofError.inlineTooLarge }
            return try read(fd, bytes: size)
        }
    }
}
