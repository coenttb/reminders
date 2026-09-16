# Packages

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Package.swift

- `let package = Package(` — The platform-free core of one example: the domain, the application layer over it, its SQLite stored form, and its TCA26 feature. Nothing here imports SwiftUI, SwiftData, UIKit, or AppKit; the Apple, server, and web layers depend on this package, never the reverse. Every target has one test target.

## reminders-apple/Package.swift

- `let package = Package(` — The Apple layer of one example: SwiftUI presentation and the application layer that drives the core's TCA26 feature. Depends on the example's core by URL; the workspace resolves it to the sibling checkout.
