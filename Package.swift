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
        .executable(
            name: "digipin",
            targets: ["digipin-cli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
    ],
    targets: [
        .target(
            name: "DIGIPIN",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "digipin-cli",
            dependencies: [
                "DIGIPIN",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DIGIPINTests",
            dependencies: ["DIGIPIN"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DIGIPINCLITests",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("StrictConcurrency")
    ]
}
