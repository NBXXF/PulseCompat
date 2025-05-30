// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PulseCompat",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "Pulse", targets: ["Pulse"]),
        .library(name: "PulseProxy", targets: ["PulseProxy"]),
        .library(name: "PulseUI", targets: ["PulseUI"]),
        .library(name: "PulseLogHandler", targets: ["PulseLogHandler"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
    ],
    targets: [
        .target(name: "Pulse"),
        .target(name: "PulseProxy", dependencies: ["Pulse"]),
        .target(name: "PulseUI", dependencies: ["Pulse"]),
        .target(name: "PulseLogHandler", dependencies: ["Pulse",
                                                        .product(name: "Logging", package: "swift-log")]),
    ],
    swiftLanguageVersions: [
        .v5,
    ]
)
