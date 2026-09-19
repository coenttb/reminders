// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "reminders-architecture",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "List", targets: ["List"]),
        .library(name: "Reminder", targets: ["Reminder"]),
        .library(name: "Reminders", targets: ["Reminders"]),
        .library(name: "Reminders Dependency", targets: ["Reminders Dependency"]),
        .library(name: "Reminders Sample", targets: ["Reminders Sample"]),
        .library(name: "Reminders SQL", targets: ["Reminders SQL"]),
        .library(name: "Reminders SQLite", targets: ["Reminders SQLite"]),
        .library(name: "Reminders Feature", targets: ["Reminders Feature"]),
        .library(name: "Reminders SwiftUI", targets: ["Reminders SwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/TCA26.git", branch: "main", traits: ["Dependencies", "Clocks"]),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.39.1", traits: ["Tagged"]),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/swift-atoms/swift-operation.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", branch: "protocol-case-paths"),
        .package(url: "https://github.com/swift-molecules/swift-interface.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-interface-composable-architecture.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.6.0"),
    ],
    targets: [
        .target(
            name: "List",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminder",
            dependencies: [
                "List",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders",
            dependencies: [
                .product(name: "Interface Macro", package: "swift-interface"),
                "List",
                "Reminder",
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.enableExperimentalFeature("Lifetimes")]
        ),
        .target(
            name: "Reminders Dependency",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                "List",
                "Reminders",
            ]
        ),
        .target(
            name: "Reminders Sample",
            dependencies: [
                "List",
                "Reminder",
                "Reminders",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQL",
            dependencies: [
                "List",
                "Reminder",
                "Reminders",
                .product(name: "StructuredQueries", package: "swift-structured-queries"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders SQLite",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "GRDB", package: "GRDB.swift"),
                "List",
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Sample",
                "Reminders SQL",
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Reminders Feature",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Interface ComposableArchitecture", package: "swift-interface-composable-architecture"),
                "List",
                .product(name: "Operation", package: "swift-operation"),
                "Reminder",
                "Reminders",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.enableExperimentalFeature("Lifetimes")]
        ),
        .target(
            name: "Reminders SwiftUI",
            dependencies: [
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "Operation", package: "swift-operation"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Interface ComposableArchitecture", package: "swift-interface-composable-architecture"),
                "List",
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Feature",
                "Reminders Sample",
                "Reminders SQLite",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self), .enableExperimentalFeature("Lifetimes")]
        ),
        .testTarget(
            name: "List Tests",
            dependencies: [
                "List",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminder Tests",
            dependencies: [
                "List",
                "Reminder",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Tests",
            dependencies: [
                "List",
                .product(name: "Operation", package: "swift-operation"),
                "Reminder",
                "Reminders",
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.enableExperimentalFeature("Lifetimes")]
        ),
        .testTarget(
            name: "Reminders Sample Tests",
            dependencies: [
                "List",
                "Reminder",
                "Reminders",
                "Reminders Sample",
            ]
        ),
        .testTarget(
            name: "Reminders SQL Tests",
            dependencies: [
                "List",
                "Reminder",
                "Reminders",
                "Reminders SQL",
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders SQLite Tests",
            dependencies: [
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                "List",
                "Reminder",
                "Reminders",
                "Reminders Sample",
                "Reminders SQL",
                "Reminders SQLite",
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "Reminders Feature Tests",
            dependencies: [
                .product(name: "ComposableArchitectureTestSupport", package: "TCA26"),
                .product(name: "Operation", package: "swift-operation"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "Interface ComposableArchitecture", package: "swift-interface-composable-architecture"),
                "List",
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Feature",
                "Reminders Sample",
                "Reminders SQL",
                "Reminders SQLite",
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.enableExperimentalFeature("Lifetimes")]
        ),
        .testTarget(
            name: "Reminders SwiftUI Tests",
            dependencies: [
                .product(name: "ComposableArchitecture2", package: "TCA26"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "Interface ComposableArchitecture", package: "swift-interface-composable-architecture"),
                "List",
                "Reminder",
                "Reminders",
                "Reminders Dependency",
                "Reminders Feature",
                "Reminders Sample",
                "Reminders SQLite",
                "Reminders SwiftUI",
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self), .enableExperimentalFeature("Lifetimes")]
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

// Integration consumers enforce import visibility at the compilation boundary.
for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [.treatAllWarnings(as: .error)]
}
