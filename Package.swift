// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitConfigs",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitConfigs",
            path: "Sources/GitConfigs"
        ),
    ]
)
