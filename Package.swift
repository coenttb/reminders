// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "reminders",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "Reminders", targets: ["Reminders"]),
        .library(name: "Reminders Interface", targets: ["Reminders Interface"]),
        .library(name: "Reminders Sample", targets: ["Reminders Sample"]),
        .library(name: "Reminders SQLiteData", targets: ["Reminders SQLiteData"]),
        .library(name: "Reminders Feature", targets: ["Reminders Feature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/TCA26.git", branch: "main", traits: ["Dependencies", "Clocks"]),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/coenttb/organizing", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-foundation-extensions.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Reminders",
            dependencies: [
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Interface",
            dependencies: [
                "Reminders",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "FoundationInternationalization Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Sample",
            dependencies: [
                "Reminders",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQLiteData",
            dependencies: [
                "Reminders",
                "Reminders Interface",
                "Reminders Sample",
                .product(name: "Organizing", package: "organizing"),
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Feature",
            dependencies: [
                "Reminders",
                "Reminders Interface",
                "Reminders Sample",
                "Reminders SQLiteData",
                .product(name: "Organizing", package: "organizing"),
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Tests",
            dependencies: [
                "Reminders",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Interface Tests",
            dependencies: [
                "Reminders",
                "Reminders Interface",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Sample Tests",
            dependencies: [
                "Reminders",
                "Reminders Sample",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders SQLiteData Tests",
            dependencies: [
                "Reminders SQLiteData",
                "Reminders Sample",
                .product(name: "FoundationEssentials Extensions", package: "swift-foundation-extensions"),
                .product(name: "Organizing", package: "organizing"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Feature Tests",
            dependencies: [
                "Reminders Feature",
                "Reminders Sample",
                .product(name: "Organizing", package: "organizing"),
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
