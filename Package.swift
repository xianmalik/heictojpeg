// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "heictojpeg",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "heictojpeg", targets: ["CLI"]),
    ],
    targets: [
        .target(name: "HeicConverter"),
        .executableTarget(name: "CLI", dependencies: ["HeicConverter"]),
        .executableTarget(
            name: "HeicApp",
            dependencies: ["HeicConverter"],
            path: "Sources/App",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
