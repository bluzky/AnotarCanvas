// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnotarCanvas",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AnotarCanvas",
            targets: ["AnotarCanvas"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/nicklockwood/SVGPath.git",
            from: "1.3.0"
        )
    ],
    targets: [
        .target(
            name: "AnotarCanvas",
            dependencies: [
                .product(name: "SVGPath", package: "SVGPath")
            ],
            path: "Sources/AnotarCanvas"
        ),
        .testTarget(
            name: "AnotarCanvasTests",
            dependencies: ["AnotarCanvas"],
            path: "Tests/AnotarCanvasTests"
        )
    ]
)
