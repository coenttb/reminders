# Domain-first SwiftUI presentations

The behavioral baseline is Reminders Architecture `fc81b0d` and the Interface–TCA
bridge `5beaa9a`. The user validated that baseline on their iPhone. The original
aspirational checkpoint is `335364a`; this document describes the final design.

## Universal naming rule

A domain's primary presentation is a concrete nested `Domain.View`. An additional
presentation is introduced only when a distinct role is actually needed, and is a
concrete nested type named for that role. No empty presentation namespace, framework
suffix, or special root-screen exception is used. No compatibility aliases retain
obsolete spellings.

Each view's inputs, View conformance, rendering body and private presentation helpers
live in one declaration under its domain. The `@View` macro derives construction and,
when explicitly requested, injects the existing feature store. It does not choose the
store from lexical nesting: the read summary intentionally requires the root store.

```swift
extension Reminders.Read {
    @View(Reminders.self)
    public struct View: SwiftUI::View {
        public var body: some SwiftUI::View {
            // Render the summary and use the root's canonical list commands.
        }
    }
}
```

## File-by-file inventory

| File | Domain and inputs | Derived machinery | Explicit policy |
| --- | --- | --- | --- |
| `Reminder.View.swift` | Reminder value and completion/deletion/editing closures | Public input initializer | Row layout, completion appearance/accessibility and offered intents |
| `Reminders.View.swift` | Root store | Store injection and `$store.read.page` / `$store.lists.create` presentation bindings | Navigation versus sheet, titles, initial list draft, error precedence |
| `Reminders.Read.View.swift` | Read presentation, explicitly supplied root store | Store injection, canonical child projection/sending | Summary section, counts, page selection and list deletion |
| `Reminders.Read.Page.View.swift` | Page store and title | Store injection; `EditingRows` selects the existing/new editor from canonical listing state | Row renderers, complete/delete/edit commands, new draft's list, blank-space gesture, toolbar and errors |
| `Reminders.Update.View.swift` | Existing editing store | Store injection, field bindings, local focus implementation | Editable fields, focus on presentation, submit dismisses |
| `Reminders.Lists.Create.View.swift` | Existing requesting store | Store injection, request bindings and canonical submission | Field label, blank/in-flight validation, cancel/Done and error section |
| `Reminders.Live.swift` | Actual dependency implementation | Existing store/feature initialization | Database bootstrap, debug seed, initial state, failure policy and root lifetime |

The host, consumer tests and documentation use the same rule. There are no extra
presentation wrappers or hand-written input initializers. Direct Operation/Tagged
imports that the presentation declarations no longer need were removed. The live
composition root is a factory, not a presentation, and retains its descriptive name.

## Algebra and single responsibility

View inputs form a product. The existing bridge macro constructs that product; it
neither duplicates domain data nor derives business actions. Required child projections
compose through the canonical feature tree; optional child bindings reuse TCA's state
projection and action injection. Clearing a presentation ends its installed lifetime.
Ordinary writable field bindings continue using SwiftUI/TCA's key-path mechanism.

`EditingRows` consumes the listing's rows, identity and selected draft lens. It renders
one substituted editor for an existing row, or one new draft after the rows, without a
parallel row model. The editor owns focus through the reusable `focusOnPresentation`
modifier. Dismissal still invokes the existing editing feature's commit policy.

The remaining intent closures are meaningful: completion chooses the inverse of the
current completion value; deletion chooses a record identifier; editing chooses an
existing record. These are different operations, not interchangeable fields that a
renderer can infer from the product algebra. The blank-space gesture and draft's list
are also explicit application choices. Replacing them with inferred conventions would
change semantics or move policy into a generic component.

Likewise, labels, layout, navigation style, titles, error precedence, validation,
submission, bootstrap and seeding are not determined by a type's product/sum/lens
structure. Their explicit declarations are the outcome of the conceptual pass, not
unfinished machinery. No new package, target, macro or parallel domain model is needed
for the final naming and declaration simplification.

## Why the nested view is a distinct value

An operation contains executable domain capabilities. Its presentation receives a
store running an editing or requesting session. These are different values with
different lifetimes; the nested view is not a duplicate domain declaration.

Two actual Swift 6.4 checks performed before this refactor established the relevant
boundaries: extensions cannot contain stored properties, and the existing
`Reminders.Update` cannot acquire ordinary SwiftUI View conformance because its TCA
`Body` is a feature, not a SwiftUI View. The current input macro also intentionally
requires a struct. Altering that macro restriction would not solve storage or Body.
A nested type named View successfully used the existing @View macro in the compiler
check. This refactor follows that supported design without absorbing UI storage into
operation values or renaming TCA's conformance requirements.

## Validation and audit

All static source, consumer and documentation changes precede builds/tests. Use only
`reminders-architecture.xcworkspace`: its thirteen local packages include every affected
repository, manifests retain URL dependencies, platform minimums are 27, and integration
consumers enforce MemberImportVisibility with warnings treated as errors.

Consumer coverage exercises all canonical view constructors, including the read view's
explicit root capability and the editor's shared state. Existing tests retain request
routing, observation, persistence, failure, ancestor, cancellation and presentation
lifetime coverage. The existing Reminders UI Tests scheme covers the real UI flow when
the simulator runtime responds.

The current refactor passed macOS tests and iOS simulator compilation and execution.
The simulator required one normal boot of the existing task-owned device; no service
restarts, resets, new devices or unrelated environment changes were needed. Baseline
iPhone validation remains separate from these new results.

| Validation | Current result | Evidence |
| --- | --- | --- |
| macOS workspace tests | 129 tests, 130 executions; zero failures/skips/runtime warnings | `Test-Reminders Architecture-2026.09.20_00-33-06-+0200.xcresult` |
| iOS simulator app and UI-test compilation | Succeeded for arm64 | `/tmp/reminders-canonical-view-ios.log` |
| iPhone 17 / iOS 27 UI suite | One end-to-end test passed; zero failures/skips/runtime warnings | `Test-Reminders UI Tests-2026.09.20_00-36-13-+0200.xcresult` |

The result bundles reside in `/tmp/institute-reminders-derived/Logs/Test`.
[Eight screenshots and matching accessibility hierarchies](Documentation/SwiftUI-Validation/README.md)
record the actual app. The UI test verifies navigation, list cancel/create, reminder
create/edit/complete, blank discard, single-editor switching, Return submission,
persistence across relaunch, reminder deletion and list cleanup.

Commands, all from this repository:

```sh
xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Reminders Architecture' -destination 'platform=macOS' \
  -derivedDataPath /tmp/institute-reminders-derived -jobs 2 test

xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Reminders UI Tests' \
  -destination 'platform=iOS Simulator,id=1EC882FE-7067-44C2-B068-F52B6790A536' \
  -derivedDataPath /tmp/institute-reminders-derived -jobs 2 build-for-testing

xcodebuild -workspace reminders-architecture.xcworkspace \
  -scheme 'Reminders UI Tests' \
  -destination 'platform=iOS Simulator,id=1EC882FE-7067-44C2-B068-F52B6790A536' \
  -derivedDataPath /tmp/institute-reminders-derived \
  -parallel-testing-enabled NO test-without-building
```

### Requirement audit

- **Uniform concrete presentations:** all six canonical types, their files, callers,
  host, consumer tests and documentation use Domain.View; the empty namespace and
  obsolete compatibility spellings are absent.
- **Complete conceptual pass:** the inventory covers all seven source files. Inputs,
  body and helpers are co-located; unnecessary imports and declaration scaffolding
  were removed. Each remaining explicit policy has a semantic reason above.
- **No domain duplication:** the existing macro, store projections and editing
  interpretation are reused. No domain, feature, runtime state or macro emission
  was reimplemented or added. The bridge change is documentation only.
- **Capabilities and lifetimes:** read explicitly receives the root store; the
  consumer regression verifies editor writes reach root state. Existing feature
  regressions and the real UI persistence/dismissal flow pass.
- **Workspace and platform constraints:** all thirteen local package references
  remain present, all explicit platform minimums are 27, manifests retain URLs,
  and consumers keep MemberImportVisibility and warnings as errors.
- **Validation provenance:** static changes preceded builds; current results above
  validate this refactor rather than relying on the baseline's user device report.
- **Checkpoint discipline:** changes remain on the existing branches and are
  committed with the configured human identity; nothing is pushed.
