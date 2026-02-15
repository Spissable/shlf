// swift-tools-version: 6.0

import Foundation
import PackageDescription

let package = Package(
    name: "shlf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "shlf", targets: ["Shlf"])
    ],
    targets: {
        var targets: [Target] = [
            .executableTarget(
                name: "Shlf",
                path: "Sources/Shlf"
            )
        ]
        #if swift(>=1) // Always true — allows file-system check at manifest evaluation time
        let testsPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Tests/ShlfTests")
            .path
        if FileManager.default.fileExists(atPath: testsPath) {
            targets.append(
                .testTarget(
                    name: "ShlfTests",
                    dependencies: ["Shlf"],
                    path: "Tests/ShlfTests"
                )
            )
        }
        #endif
        return targets
    }()
)
