// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test_game",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "test_game",
            targets: ["test_game"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "test_game",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]),
        .testTarget(
            name: "test_gameTests",
            dependencies: ["test_game"]),
    ]
)
