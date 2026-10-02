// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "P2PersistenceProof",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "p2-proof", targets: ["ProofCLI"])],
    targets: [
        .target(name: "PersistenceProof"),
        .executableTarget(name: "ProofCLI", dependencies: ["PersistenceProof"]),
        .testTarget(name: "PersistenceProofTests", dependencies: ["PersistenceProof"])
    ]
)
