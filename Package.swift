// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BencodeKit",
    products: [
        .library(
            name: "BencodeKit",
            targets: ["BencodeKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BencodeKit",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "BencodeTests",
            dependencies: ["BencodeKit"],
            path: "Tests"
        ),
    ]
)
