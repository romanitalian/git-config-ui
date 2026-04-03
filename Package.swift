// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitConfigUI",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitConfigUI",
            path: "Sources/GitConfigUI"
        ),
    ]
)
