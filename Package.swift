// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CloneWatch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "CloneWatchCore", targets: ["CloneWatchCore"]),
        .executable(name: "CloneWatchApp", targets: ["CloneWatchApp"]),
        .executable(name: "CloneWatchDocsTool", targets: ["CloneWatchDocsTool"]),
    ],
    targets: [
        .target(
            name: "CloneWatchCore",
            path: "Sources/CloneWatchCore"
        ),
        .executableTarget(
            name: "CloneWatchApp",
            dependencies: ["CloneWatchCore"],
            path: "Sources/CloneWatchApp"
        ),
        .executableTarget(
            name: "CloneWatchDocsTool",
            dependencies: ["CloneWatchCore"],
            path: "Sources/CloneWatchDocsTool"
        ),
        .testTarget(
            name: "CloneWatchCoreTests",
            dependencies: ["CloneWatchCore"],
            path: "Tests/CloneWatchCoreTests"
        ),
    ]
)
