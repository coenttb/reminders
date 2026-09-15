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
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "2.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/swift-molecules/swift-foundation-extensions.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Reminders",
            dependencies: [
                .product(name: "Foundation Extensions", package: "swift-foundation-extensions"),
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
                .product(name: "IssueReporting", package: "swift-issue-reporting"),
            ]
        ),
        .testTarget(
            name: "Reminders Tests",
            dependencies: [
                "Reminders",
            ]
        ),
        .testTarget(
            name: "Reminders SQLiteData Tests",
            dependencies: [
                "Reminders SQLiteData",
            ]
        ),
        .testTarget(
            name: "Reminders Feature Tests",
            dependencies: [
                "Reminders Feature",
                .product(name: "ComposableArchitectureTestSupport", package: "TCA26"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
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
