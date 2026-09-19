# Domain-first implementation validation

Validated September 19–20, 2026 with Xcode 27.0 (27A266a), Apple Swift 6.4
(swiftlang-6.4.0.34.1), and macOS 27.0. The complete static refactor preceded
builds and tests. All commands below run from this package and use its exact workspace;
local dependencies resolve through workspace references, with URL dependencies retained
in package manifests.

## Commands

```sh
xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Reminders Architecture' -destination 'platform=macOS' \
  -derivedDataPath /tmp/institute-reminders-derived -jobs 1 test

xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Feature Runtime Tests' -destination 'platform=macOS' \
  -derivedDataPath /tmp/institute-reminders-derived \
  -only-testing:ComposableArchitecture2Tests/IfLetFeatureTests \
  -only-testing:ComposableArchitecture2Tests/ScopedStoreDiagnosticsTests test

xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Feature Macro Tests' -destination 'platform=macOS' \
  -derivedDataPath /tmp/institute-reminders-derived \
  -only-testing:MacroTests/FeatureMacroTests test

xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Reminders Architecture' -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/institute-reminders-derived build
```

## Results

Result bundles are local artifacts under `/tmp/institute-reminders-derived/Logs/Test`.

| Validation | Result | Bundle |
| --- | --- | --- |
| Reminders Architecture | 122 tests, 123 executions passed | `Test-Reminders Architecture-2026.09.20_00-00-33-+0200.xcresult` |
| TCA scope/lifetime runtime regressions | 13 tests passed | `Test-Feature Runtime Tests-2026.09.20_00-02-11-+0200.xcresult` |
| TCA feature derivation | 52 tests passed | `Test-Feature Macro Tests-2026.09.19_23-56-30-+0200.xcresult` |
| iOS simulator | Build succeeded for arm64 and x86_64 | `/tmp/reminders-domain-first-ios.log` |

Test results contain zero failures, skips, and runtime warnings. The simulator binary's
load commands report `IOSSIMULATOR`, minimum OS 27.0 and SDK 27.0 for both architectures.
This validates compilation for iOS; runtime tests above ran on macOS.

## Integration audit

- All thirteen local package references are present, including all four modified repositories:
  Reminders Architecture, swift-interface, swift-interface-composable-architecture, and TCA26.
  No new package or parallel domain representation was introduced.
- Every workspace package's explicit platform minimums are 27. The app enables
  MemberImportVisibility and treats Swift warnings as errors; no diagnostic was disabled.
- All eight remaining Reminders Feature files implement the inventory in
  [FEATURE-SYNTAX.md](FEATURE-SYNTAX.md). Three obsolete marker-conformance files were removed.
  Consumer feature declarations contain no `.Run`, `.Structure`, or handwritten State/Action aliases.
- The bridge consumes Interface metadata and attaches TCA's macro to its generated implementation.
  It does not import TCA macro Core or synthesize another copy of the domain call algebra.
- Regression coverage includes canonical calls without CasePathable adoption, interpretation
  inference without an expected type, same-typed child routing, typed draft lenses and complement
  preservation, ancestor instance selection, observation cancellation, request errors, actionless
  scopes and SwiftUI bindings, and dismissal-before-execution for root/scoped deletion failures.
- Existing views and property-based sending compile unchanged. Root, child, and page execution
  retain their own task/error ownership. Unrelated deletion leaves the page presented.
- Compiler fixtures verify rejection of extension macros on extensions, ambiguous bare Feature
  macro use, and opaque Feature values where EditingFeature is required. Additional observed
  compiler boundaries and their smallest syntax deviations are documented in FEATURE-SYNTAX.md.

The focused TCA runtime selection compiles the complete runtime test target but executes only
the two named suites. It is not a claim that every upstream TCA test was run.
