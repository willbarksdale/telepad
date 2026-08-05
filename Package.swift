// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TelePad",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TelePad",
            path: "Sources/TelePad"
        )
    ]
)
