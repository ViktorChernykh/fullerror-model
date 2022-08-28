// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "fullerror-model",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "FullErrorModel", targets: ["FullErrorModel"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "FullErrorModel", dependencies: []),
        .testTarget(name: "FullErrorModelTests", dependencies: [])
    ]
)
