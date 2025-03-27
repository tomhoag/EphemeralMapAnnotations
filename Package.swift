
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EphemeralMapAnnotations",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EphemeralMapAnnotations",
            targets: ["EphemeralMapAnnotations"]),
    ],
    targets: [
        .target(
            name: "EphemeralMapAnnotations",
            dependencies: []),
        .testTarget(
            name: "EphemeralMapAnnotationsTests",
            dependencies: ["EphemeralMapAnnotations"]),
    ]
)
