// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PerfectRE2",
    products: [
        .library(
            name: "PerfectRE2",
            targets: ["PerfectRE2"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "re2api",
            dependencies: []),
        .target(
            name: "PerfectRE2",
            dependencies: ["re2api"]),
        .testTarget(
            name: "PerfectRE2Tests",
            dependencies: ["PerfectRE2"]),
    ]
)
