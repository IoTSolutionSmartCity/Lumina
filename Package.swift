// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lumina",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Lumina",
            targets: ["Lumina"]),
    ],
    dependencies: [
        // Add your package dependencies here
    ],
    targets: [
        .target(
            name: "Lumina",
            path: "Source/Lumina-Swift",
            dependencies: []),
    ]
)
