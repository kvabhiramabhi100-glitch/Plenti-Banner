// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlentiBanner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlentiBanner", targets: ["PlentiBanner"]),
    ],
    targets: [
        .target(
            name: "PlentiBanner",
            resources: [.process("Resources")]
        ),
    ]
)
