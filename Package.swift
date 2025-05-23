// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WABackupExtractor",
    dependencies: [
        .package(
            url: "https://github.com/domingogallardo/SwiftWABackupAPI.git",
            from: "1.4.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "WABackupExtractor",
            dependencies: ["SwiftWABackupAPI"],
            path: "Sources"),
    ]
)
