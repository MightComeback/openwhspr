// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "openwhspr",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "OpenWhisper",
            dependencies: ["SwiftWhisper"],
            swiftSettings: [.strictConcurrency("minimal")],
                .process("Resources"),
            ]
        ),
    ]
)
