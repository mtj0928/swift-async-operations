// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-async-operators",
    platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .macCatalyst(.v16), .tvOS(.v16), .visionOS(.v1)],
    products: [
        .library(name: "AsyncOperators", targets: ["AsyncOperators"]),
    ],
    targets: [
        .target(name: "AsyncOperators"),
        .testTarget(name: "AsyncOperatorsTests", dependencies: ["AsyncOperators"]),
    ]
)
