// swift-tools-version: 5.9
// MirrorzKit — shared licensing, store, compatibility, remote-protocol and design-system
// code for the MIRRORZ macOS app and the iOS companion.
import PackageDescription

let package = Package(
    name: "MirrorzKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "MirrorzKit", targets: ["MirrorzKit"]),
    ],
    targets: [
        .target(
            name: "MirrorzKit",
            path: "Sources/MirrorzKit",
            resources: [
                // Bundled copy of server/src/compat/seed.json for offline use (spec §4).
                .copy("Resources/compat-seed.json"),
            ],
            swiftSettings: [
                // Strict concurrency diagnostics in Swift 5 language mode; the code is
                // written to be warning-free so the Swift 6 language mode is a flag flip.
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "MirrorzKitTests",
            dependencies: ["MirrorzKit"],
            path: "Tests/MirrorzKitTests",
            resources: [
                // Copy of core/tests/fixtures/license-fixtures.json (cross-language fixtures).
                .copy("Resources/license-fixtures.json"),
            ]
        ),
    ]
)
