// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnotarCanvas",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AnotarCanvas", targets: ["AnotarCanvas"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SVGPath.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "AnotarCanvas",
            dependencies: ["SVGPath"],
            swiftSettings: [
                .unsafeFlags(["-default-isolation", "MainActor"]),
            ]
        ),
        .testTarget(
            name: "AnotarCanvasTests",
            dependencies: ["AnotarCanvas"],
            swiftSettings: [
                .unsafeFlags(["-default-isolation", "MainActor"]),
            ]
        ),
    ]
)
