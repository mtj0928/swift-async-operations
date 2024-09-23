// swift-tools-version: 6.0
import Foundation
import PackageDescription

let package = Package(
    name: "swift-async-operations",
    platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .macCatalyst(.v16), .tvOS(.v16), .visionOS(.v1)],
    products: [
        .library(name: "AsyncOperations", targets: ["AsyncOperations"]),
    ],
    targets: [
        .target(name: "AsyncOperations"),
        .testTarget(name: "AsyncOperationsTests", dependencies: ["AsyncOperations"]),
    ]
)

let isDocCBuild = ProcessInfo.processInfo.environment["DOCC_BUILD"] == "1"
if isDocCBuild {
    package.dependencies += [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ]
}

