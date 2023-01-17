// swift-tools-version:5.1

import PackageDescription

let package = Package(
	name: "fullerror-model",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v10),
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
