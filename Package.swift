// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Picker",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/plate.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Economics.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Interfaces.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/ViewComponents.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Compositions.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Implementations.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Structures.git", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Picker",
            dependencies: [
                .product(name: "plate", package: "plate"),
                .product(name: "Economics", package: "Economics"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "ViewComponents", package: "ViewComponents"),
                .product(name: "Compositions", package: "Compositions"),
                .product(name: "Implementations", package: "Implementations"),
                .product(name: "Structures", package: "Structures"),
            ],
            // resources: [
            //     .process("Resources"),
            // ]
        ),
    ]
)
