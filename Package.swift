// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MaterialAuth",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MaterialAuth", targets: ["MaterialAuth"])
    ],
    targets: [
        .executableTarget(
            name: "MaterialAuth",
            path: "Sources/MaterialAuth"
        )
    ]
)
