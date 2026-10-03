// swift-tools-version: 6.0
import PackageDescription
let package = Package(name:"ManualTextProof",platforms:[.macOS(.v13)],targets:[
    .target(name:"ManualTextProof"),
    .testTarget(name:"ManualTextProofTests",dependencies:["ManualTextProof"])
])
