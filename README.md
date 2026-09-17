# Reminders

A proof of concept: a Reminders app whose domain is declared once as a protocol and derived with `@Interface`
([swift-interface](https://github.com/swift-institute/swift-interface)) — each operation keeps its real, labelled
method signature while also getting a request product, a call coproduct, prisms, folds and an exhaustive eliminator.

Start at [`Sources/Reminders/Reminders.swift`](Sources/Reminders/Reminders.swift) and the per-verb files beside it;
the features under `Sources/Reminders Feature` show the call sites.

The app layer builds on [TCA26](https://github.com/pointfreeco/TCA26), which is unreleased. It is resolved as a
URL dependency in `Package.swift` and is not vendored here; `reminders.xcworkspace` additionally expects a local
checkout at `../../pointfreeco/TCA26` for development.
