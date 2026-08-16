// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AmethystIDECore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "AmethystIDECore", targets: ["AmethystIDECore"])
    ],
    targets: [
        .target(
            name: "AmethystIDECore",
            path: "AmethystIDE"
        ),
        .testTarget(
            name: "AmethystIDECoreTests",
            dependencies: ["AmethystIDECore"],
            path: "Tests"
        )
    ]
)
