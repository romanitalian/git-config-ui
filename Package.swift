// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitConfigs",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GitConfigsLib", targets: ["GitConfigsLib"]),
        .executable(name: "GitConfigs", targets: ["GitConfigs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "7.6.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
    ],
    targets: [
        .target(
            name: "GitConfigsLib",
            path: "Sources/GitConfigsLib"
        ),
        .executableTarget(
            name: "GitConfigs",
            dependencies: ["GitConfigsLib"],
            path: "Sources/GitConfigs"
        ),
        .testTarget(
            name: "GitConfigsTests",
            dependencies: [
                "GitConfigsLib",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
            ],
            path: "Tests/GitConfigsTests"
        ),
    ]
)
