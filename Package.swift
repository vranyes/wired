// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wired",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Wired",
            path: "Sources/Wired",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
    ]
)
