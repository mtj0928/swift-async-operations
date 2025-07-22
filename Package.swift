// swift-tools-version: 6.0
import Foundation
import PackageDescription

let package = Package(
    name: "swift-async-operations",
    platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11), .macCatalyst(.v18), .tvOS(.v18), .visionOS(.v2)],
    products: [
        .library(name: "AsyncOperations", targets: ["AsyncOperations"]),
        .library(name: "V0", targets: ["V0"]),
        .library(name: "V1", targets: ["V1"]),
        .library(name: "V2", targets: ["V2"]),
    ],
    targets: [
        .target(name: "AsyncOperations"),
        .testTarget(name: "AsyncOperationsTests", dependencies: ["AsyncOperations"]),
        .target(name: "V0"),
        .target(name: "V1", dependencies: ["AsyncOperations"]),
        .target(name: "V2"),
        .testTarget(name: "PDSLTests", dependencies: ["V0", "V1", "V2", "AsyncOperations"]),
    ]
)

let isDocCBuild = ProcessInfo.processInfo.environment["DOCC_BUILD"] == "1"
if isDocCBuild {
    package.dependencies += [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ]
}
