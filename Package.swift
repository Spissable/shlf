// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "shlf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "shlf", targets: ["Shlf"])
    ],
    targets: [
        .executableTarget(
            name: "Shlf",
            path: "Sources/Shlf"
        ),
        .testTarget(
            name: "ShlfTests",
            dependencies: ["Shlf"],
            path: "Tests/ShlfTests"
        ),
    ]
)
