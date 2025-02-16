// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DIGIPIN",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "DIGIPIN",
            targets: ["DIGIPIN"]),
    ],
    targets: [
        .target(
            name: "DIGIPIN",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DIGIPINTests",
            dependencies: ["DIGIPIN"]
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("StrictConcurrency")
    ]
}
