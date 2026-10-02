import Foundation

// SHA-256 for this synthetic proof; tested against public known-answer vectors.
// No crypto dependency; integrity hashes do not authenticate hostile bundles.
public enum SHA256 {
    private static let k: [UInt32] = [
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
    ]
    private static func rotate(_ x: UInt32, _ n: UInt32) -> UInt32 { (x >> n) | (x << (32 - n)) }
    public struct Incremental {
        private var state: [UInt32] = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]
        private var pending = [UInt8]() // At most one 64-byte block, never the payload.
        private var count: UInt64 = 0
        public init() { pending.reserveCapacity(64) }
        public mutating func update(_ data: Data) {
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                count = count &+ UInt64(bytes.count)
                var offset = 0
                if !pending.isEmpty {
                    let n = min(64-pending.count, bytes.count)
                    pending.append(contentsOf: bytes.prefix(n)); offset = n
                    if pending.count == 64 {
                        let block = pending
                        block.withUnsafeBytes { compress($0) }; pending.removeAll(keepingCapacity:true)
                    }
                }
                while bytes.count-offset >= 64 {
                    compress(UnsafeRawBufferPointer(rebasing:bytes[offset..<offset+64])); offset += 64
                }
                pending.append(contentsOf:bytes.suffix(from:offset))
            }
        }
        public func hex() -> String {
            var final = self
            let bits = count &* 8
            var tail = Data([0x80])
            while (pending.count+tail.count)%64 != 56 { tail.append(0) }
            for n in stride(from:56,through:0,by:-8) { tail.append(UInt8(truncatingIfNeeded:bits >> n)) }
            final.update(tail)
            return final.state.map { String(format:"%08x",$0) }.joined()
        }
        private mutating func compress(_ block: UnsafeRawBufferPointer) {
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                for j in 0..<4 { w[i] = (w[i] << 8) | UInt32(block[i * 4 + j]) }
            }
            for i in 16..<64 {
                let a = w[i-15], b = w[i-2]
                let s0 = SHA256.rotate(a,7) ^ SHA256.rotate(a,18) ^ (a >> 3)
                let s1 = SHA256.rotate(b,17) ^ SHA256.rotate(b,19) ^ (b >> 10)
                w[i] = w[i-16] &+ s0 &+ w[i-7] &+ s1
            }
            var a=state[0], b=state[1], c=state[2], d=state[3], e=state[4], f=state[5], g=state[6], t=state[7]
            for i in 0..<64 {
                let s1 = SHA256.rotate(e,6) ^ SHA256.rotate(e,11) ^ SHA256.rotate(e,25)
                let ch = (e & f) ^ (~e & g)
                let t1 = t &+ s1 &+ ch &+ SHA256.k[i] &+ w[i]
                let s0 = SHA256.rotate(a,2) ^ SHA256.rotate(a,13) ^ SHA256.rotate(a,22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let t2 = s0 &+ maj
                t=g; g=f; f=e; e=d &+ t1; d=c; c=b; b=a; a=t1 &+ t2
            }
            let vals=[a,b,c,d,e,f,g,t]
            for i in 0..<8 { state[i] = state[i] &+ vals[i] }

        }
    }
    public static func hex(_ data: Data) -> String {
        var hash=Incremental();hash.update(data);return hash.hex()
    }
}
