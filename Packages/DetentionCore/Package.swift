// swift-tools-version: 6.0
import PackageDescription

// Detention math, copy and demo data. Foundation only, so it builds and tests on
// macOS, iOS and Linux (`swift test` in this folder).
let package = Package(
    name: "DetentionCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "DetentionCore", targets: ["DetentionCore"])
    ],
    targets: [
        .target(name: "DetentionCore"),
        .testTarget(name: "DetentionCoreTests", dependencies: ["DetentionCore"]),
    ]
)
