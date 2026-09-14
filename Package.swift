// swift-tools-version: 6.4

import PackageDescription

// The platform-free core of one example: the domain, its SQLite stored form,
// and its TCA26 feature. Nothing here imports SwiftUI, SwiftData, UIKit, or
// AppKit; the Apple, server, and web layers depend on this package, never the
// reverse. Every target has one test target.
let package = Package(
    name: "reminders",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "Reminders", targets: ["Reminders"]),
        .library(name: "Reminders SQLiteData", targets: ["Reminders SQLiteData"]),
        .library(name: "Reminders Feature", targets: ["Reminders Feature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/TCA26.git", branch: "main", traits: ["Dependencies", "Clocks"]),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.39.2", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "Reminders",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQLiteData",
            dependencies: [
                "Reminders",
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Feature",
            dependencies: [
                "Reminders",
                "Reminders SQLiteData",
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Tests",
            dependencies: [
                "Reminders",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders SQLiteData Tests",
            dependencies: [
                "Reminders",
                "Reminders SQLiteData",
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Feature Tests",
            dependencies: [
                "Reminders",
                "Reminders SQLiteData",
                "Reminders Feature",
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "ComposableArchitectureTestSupport", package: "TCA26"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
