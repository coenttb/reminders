// swift-tools-version: 6.4

import PackageDescription

// The Apple layer of one example: SwiftUI presentation and the application
// layer that owns the domain value through the core's TCA26 feature. Depends
// on the example's core by URL; the workspace resolves it to the sibling checkout.
let package = Package(
    name: "reminders-apple",
    platforms: [.iOS(.v27)],
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
    ],
    targets: [
        .target(
            name: "Reminders View",
            dependencies: [
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "Reminders App",
            dependencies: [
                .product(name: "Reminders", package: "reminders"),
                .product(name: "Reminders Feature", package: "reminders"),
                "Reminders View",
                .product(name: "SwiftUI Extensions", package: "swiftui-extensions"),
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
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "Reminders App Tests",
            dependencies: [
                "Reminders App",
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
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
