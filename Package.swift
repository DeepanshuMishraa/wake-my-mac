// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WatchMyMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WatchMyMac", targets: ["WatchMyMac"]),
        .executable(name: "WakeMyMacHelper", targets: ["WakeMyMacHelper"])
    ],
    dependencies: [
        .package(url: "https://github.com/willdale/SwiftUICharts.git", from: "2.9.9")
    ],
    targets: [
        .executableTarget(
            name: "WatchMyMac",
            dependencies: [
                "WakeHelperShared",
                "Sparkle",
                .product(name: "SwiftUICharts", package: "SwiftUICharts")
            ],
            path: "Sources/HoldMyLid",
            exclude: [
                "Resources/AppIcon.png",
                "Resources/Assets.xcassets"
            ],
            resources: [
                .copy("Resources/AgentIcons"),
                .copy("Resources/Integrations")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .target(
            name: "WakeHelperShared",
            path: "Sources/WakeHelperShared"
        ),
        .executableTarget(
            name: "WakeMyMacHelper",
            dependencies: ["WakeHelperShared"],
            path: "Sources/WakeMyMacHelper"
        ),
        .testTarget(
            name: "WatchMyMacTests",
            dependencies: ["WatchMyMac", "WakeHelperShared"],
            path: "Tests/HoldMyLidTests"
        ),
        .binaryTarget(
            name: "Sparkle",
            url: "https://github.com/sparkle-project/Sparkle/releases/download/2.9.2/Sparkle-for-Swift-Package-Manager.zip",
            checksum: "b83e37436774556ed055e0244b297ef2c790e0737393bf65bf495fcbba6eed65"
        )
    ]
)
