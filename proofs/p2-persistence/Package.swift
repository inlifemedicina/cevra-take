// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "P2PersistenceProof",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "p2-proof", targets: ["ProofCLI"])],
    dependencies: [.package(path: "../p4-teleprompter")],
    targets: [
        .target(name: "PersistenceProof", dependencies: [.product(name: "ManualTextProof", package: "p4-teleprompter")]),
        .executableTarget(name: "ProofCLI", dependencies: ["PersistenceProof"]),
        .testTarget(name: "PersistenceProofTests", dependencies: ["PersistenceProof"])
    ]
)
