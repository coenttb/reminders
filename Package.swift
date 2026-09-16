// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "reminders",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Reminder", targets: ["Reminder"]),
        .library(name: "Reminders", targets: ["Reminders"]),
        .library(name: "Reminders Session", targets: ["Reminders Session"]),
        .library(name: "Reminders Dependency", targets: ["Reminders Dependency"]),
        .library(name: "Reminders Sample", targets: ["Reminders Sample"]),
        .library(name: "Reminders SQL", targets: ["Reminders SQL"]),
        .library(name: "Reminders SQLite", targets: ["Reminders SQLite"]),
        .library(name: "Reminders PostgreSQL", targets: ["Reminders PostgreSQL"]),
        .library(name: "Reminders Feature", targets: ["Reminders Feature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/TCA26.git", branch: "main", traits: ["Dependencies", "Clocks"]),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.39.1", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", branch: "protocol-case-paths"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/swift-atoms/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-foundation-extensions.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminder",
            dependencies: [
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                "Reminder",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Session",
            dependencies: [
                "Reminder",
                "Reminders",
            ]
        ),
        .target(
            name: "Reminders Dependency",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Reminders",
                "Reminders Session",
            ]
        ),
        .target(
            name: "Reminders Sample",
            dependencies: [
                "Reminder",
                "Reminders",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQL",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Session",
                "Models",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "StructuredQueries", package: "swift-structured-queries"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQLite",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Session",
                "Reminders Sample",
                "Reminders SQL",
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Models",
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders PostgreSQL",
            dependencies: [
                "Reminders SQL",
            ]
        ),
        .target(
            name: "Reminders Feature",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Session",
                "Reminders SQLite",
                "Models",
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "FoundationInternationalization Extensions", package: "swift-foundation-extensions"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Models Tests",
            dependencies: [
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminder Tests",
            dependencies: [
                "Reminder",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Tests",
            dependencies: [
                "Reminder",
                "Reminders",
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Sample Tests",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Sample",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders SQL Tests",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Session",
                "Reminders SQL",
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders SQLite Tests",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Sample",
                "Reminders Session",
                "Reminders SQL",
                "Reminders SQLite",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Feature Tests",
            dependencies: [
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Session",
                "Reminders Feature",
                "Reminders Sample",
                "Models",
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "ComposableArchitectureTestSupport", package: "TCA26"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
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
