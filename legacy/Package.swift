// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FomoDoroLegacy",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "FomoDoroLegacy",
            path: "Sources/FomoDoroLegacy"
        )
    ]
)
