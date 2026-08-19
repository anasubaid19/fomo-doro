// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FomoDoroLegacy",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.2")
    ],
    targets: [
        .executableTarget(
            name: "FomoDoroLegacy",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/FomoDoroLegacy",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .testTarget(
            name: "FomoDoroLegacyTests",
            dependencies: ["FomoDoroLegacy"],
            path: "Tests/FomoDoroLegacyTests"
        )
    ]
)
