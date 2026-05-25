// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BetterWarp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BetterWarp", targets: ["BetterWarp"])
    ],
    targets: [
        .target(
            name: "BetterWarpCore",
            path: "Sources/BetterWarpCore"
        ),
        .executableTarget(
            name: "BetterWarp",
            dependencies: ["BetterWarpCore"],
            path: "Sources/BetterWarp"
        ),
        .executableTarget(
            name: "BetterWarpCoreTestRunner",
            dependencies: ["BetterWarpCore"],
            path: "Tests/BetterWarpCoreTestRunner"
        )
    ]
)
