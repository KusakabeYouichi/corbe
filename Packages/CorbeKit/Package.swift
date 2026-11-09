// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CorbeKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CorbeCore", targets: ["CorbeCore"]),
        .library(name: "CorbeUI", targets: ["CorbeUI"])
    ],
    targets: [
        .target(name: "CorbeCore", resources: [.process("Resources")]),
        .target(name: "CorbeUI", dependencies: ["CorbeCore"], resources: [.process("Resources")]),
        .testTarget(name: "CorbeCoreTests", dependencies: ["CorbeCore"])
    ]
)
