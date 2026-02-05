// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "openwhspr",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "OpenWhisper",
            dependencies: ["SwiftWhisper"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
