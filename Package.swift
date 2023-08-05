// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "ElectrumX",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "ElectrumX", targets: ["ElectrumX"])
    ],
    dependencies: [
        .package(url: "https://github.com/anquii/JSONRPC2.git", exact: "2.0.0")
    ],
    targets: [
        .target(name: "ElectrumX", dependencies: ["JSONRPC2"]),
        .testTarget(name: "ElectrumXTests", dependencies: ["ElectrumX"])
    ]
)
