// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkKit",

    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],

    products: [
        .library(
            name: "NetworkKit",
            targets: ["NetworkKit"]
        )
    ],

    targets: [
        .target(
            name: "NetworkKit"
        ),

        .testTarget(
            name: "NetworkKitTests",
            dependencies: ["NetworkKit"]
        )
    ]
)
