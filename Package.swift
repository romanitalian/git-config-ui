// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitToggleUserUI",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitToggleUserUI",
            path: "Sources/GitToggleUserUI"
        ),
    ]
)
