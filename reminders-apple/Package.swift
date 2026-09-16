// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "reminders-apple",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "Reminders View", targets: ["Reminders View"]),
        .library(name: "Reminders App", targets: ["Reminders App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/reminders", branch: "main"),
        .package(url: "https://github.com/pointfreeco/TCA26.git", branch: "main", traits: ["Dependencies", "Clocks"]),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/coenttb/swiftui-extensions", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-foundation-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0", traits: ["Tagged"]),
    ],
    targets: [
        .target(
            name: "Reminders View",
            dependencies: [
                .product(name: "Reminder", package: "reminders"),
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Reminders Dependency", package: "reminders"),
                .product(name: "Reminders Feature", package: "reminders"),
                .product(name: "Reminders Sample", package: "reminders"),
                .product(name: "Models", package: "reminders"),
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "Reminders App",
            dependencies: [
                .product(name: "Reminder", package: "reminders"),
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Reminders Dependency", package: "reminders"),
                .product(name: "Reminders Sample", package: "reminders"),
                .product(name: "Reminders SQL", package: "reminders"),
                .product(name: "Reminders SQLite", package: "reminders"),
                .product(name: "Reminders Feature", package: "reminders"),
                .product(name: "Models", package: "reminders"),
                "Reminders View",
                .product(name: "SwiftUI Extensions", package: "swiftui-extensions"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "Reminders View Tests",
            dependencies: [
                "Reminders View",
                .product(name: "Reminder", package: "reminders"),
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Reminders Dependency", package: "reminders"),
                .product(name: "Reminders Feature", package: "reminders"),
                .product(name: "Models", package: "reminders"),
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "Reminders App Tests",
            dependencies: [
                "Reminders App",
                .product(name: "Reminder", package: "reminders"),
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Reminders Dependency", package: "reminders"),
                .product(name: "Reminders Sample", package: "reminders"),
                .product(name: "Reminders SQL", package: "reminders"),
                .product(name: "Reminders SQLite", package: "reminders"),
                .product(name: "Reminders Feature", package: "reminders"),
                .product(name: "Models", package: "reminders"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
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
