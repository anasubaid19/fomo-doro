// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FomoDoro",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FomoDoro",
            path: "Sources/FomoDoro"
        )
    ]
)
