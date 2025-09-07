// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TimeMeUp",
    platforms: [
        .macOS(.v13),
    ],
    targets: [
        // Executable target: builds the main TimeMeUp.app
        .executableTarget(
            name: "TimeMeUp"
        ),
    ]
)
