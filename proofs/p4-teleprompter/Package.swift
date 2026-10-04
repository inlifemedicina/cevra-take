// swift-tools-version: 6.0
import PackageDescription
let package = Package(name:"ManualTextProof",platforms:[.macOS(.v13),.iOS(.v16)],products:[.library(name:"ManualTextProof",targets:["ManualTextProof"])],targets:[
    .target(name:"ManualTextProof"),
    .testTarget(name:"ManualTextProofTests",dependencies:["ManualTextProof"])
])
