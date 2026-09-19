# Domain-first feature syntax

This implements the aspirational design at `b689cff`, using `f8a468f` as the behavioral baseline. The domain remains declared once with `@Interface`. Feature declarations choose interpretations and relationships; macros derive the operation symbols, state products, action routes, scopes, projections, and task storage.

## File-by-file result

| Aspirational file | Implemented result | Remaining domain choice |
| --- | --- | --- |
| `Reminders+Feature.swift` | `Child(\.read)` and `Child(\.lists)` derive required state and scoped action routes. One `.dismiss` rule covers root and scoped list deletion. | Which children live with the root; which deletion closes which page, and when. |
| `Reminders.Read+Feature.swift` | `Observing(self)` and `Presenting(\.page)` derive observation and optional page state. | Follow the primary stream; give pages a presentation lifetime. |
| `Reminders.Lists+Feature.swift` | `Presenting(\.create)` derives form presentation and retains the canonical list commands. | The create form is optional. |
| `Reminders.Lists.Create+Feature.swift` | `Requesting(self)` reuses the canonical request and call. No handwritten aliases or `.Run`. | Submit explicitly, retain failure, dismiss on success. |
| `Reminders.Read.Page+Feature.swift` | `Listing(self, rows: \.rows, commands: Reminders.self, editing: \.editing, deleting: \.delete?.id)` derives the row coordinate and reuses editing state. | Rows, ancestor capabilities, editing policy, deletion identity. |
| `Reminders.Update+Feature.swift` | `Editing(in: Reminders.self, \.editing)` reuses the exact same editing state and the enclosing instance's policy. | Interpret this operation as the complete editing workflow, not merely a one-shot update. |
| `Reminders+Editing.swift` | `@EditingPolicy` derives the draft coordinate from `draft: \.draft`; operation values are passed directly. The result is `some EditingFeature`. | Create/update/delete roles, writable draft, blank handling, ignored update failure. |
| `Reminder+EditableRecord.swift` | Removed. `Reminder` has no bridge marker conformance. | The selected writable key path supplies the lens. |
| `Reminders.Read.Page.Value+ListingValue.swift` | Removed. The result value has no bridge marker conformance. | The selected rows key path supplies the projection. |
| `Reminders+CasePathable.swift` | Removed. Canonical leaf calls need no consumer optics conformance. | Generated routed action sums still use TCA's case-path derivation. |
| `Reminders.Read.Page.State+List.swift` | Replaced by `Reminders.Read.Filter+List.swift`. State forwards to the existing request; no second filter is stored. | A list filter has a list identifier; `.all` does not. |

The views retain `store.read.page`, `store.lists.create`, `store.lists.delete(id)`, `store.delete(id)`, `store.update.complete(id, done)`, `store.send()`, and `.init(original)` for editing. There are no surrogate top-level feature types.

## Algebra and responsibility

Interface owns the canonical product coordinates, distinguished primary operation, indexed input/output/failure sorts, call coproduct, embeddings, and optics. `InterfacePrimary` is derived metadata tying the original owner to its original primary symbol. It does not choose observation or request behavior.

The bridge's `Feature` macro reads interpretation policy from the source body. Required children form a product of states and a sum of routed actions. Presentation adds an optional child state. Observation follows a stream and contributes no action of its own. The macro consumes Interface metadata and attaches TCA's `@Feature` to the generated implementation; it does not import or reproduce TCA's macro Core. The older descriptor-based `@FeatureComposition` remains an alternate entry point to the same composition derivation.

`DraftProjection` and `ListingProjection` are typed coordinates, not parallel domain data. `@EditingPolicy` derives the former from the selected draft lens; the listing interpretation derives the latter from the selected rows lens. Editing keeps identity and complementary fields in the original record. A listing overlays its current draft on observed rows without replacing the underlying domain value.

`EditingFeature` exposes the selected lens and commit contract through an opaque result. Listing stores the feature through TCA's existing feature abstraction; it never downcasts the opaque result or reconstructs the policy. Blank handling and ignored failures are explicit policy, not consequences of product or lens laws.

TCA's actionless scopes use the unique injection from `Never`. They no longer demand a nominal `CasePathable` conformance from a parent action that contributes no child actions. Declared action routes take precedence over the actionless fallback.

## Execution and lifetime

Property sending routes a command into its selected required child when that child interprets the call. Explicit `.call(...)` preserves root execution. `InterfaceCalls.interfaceCall` projects a routed action back to its canonical call for policy matching only; it does not change dispatch, execute the command, or move its task.

The dismissal rule closes only the matching page, before command execution. It covers both root and scoped list deletion. A failure leaves that page closed and remains on the task that owns the original route. An unrelated list deletion leaves the page open. Page-originated calls retain their page interpretation and are not promoted into root navigation actions.

Every composed child receives the actual owner through a lexical feature-environment binding. `commands: Reminders.self` selects that binding; it does not construct another implementation or consult a global dependency. A standalone page or editor still requires `.interface(reminders)`. An explicit nearer binding can select a different supplied instance.

## Necessary differences from the sketch

- **Explicit `: FeatureProtocol`.** Swift rejects an extension macro attached to an extension. A member macro cannot add an inheritance clause to its source declaration. Each original domain type therefore has an explicit source conformance. No macro tries to extend an unrelated child or relies on an extension macro nested in extension output.
- **Qualified `@Interface_ComposableArchitecture.Feature`.** Both imported libraries expose a zero-argument `Feature` macro; unqualified use is ambiguous. Selectively importing only TCA's protocol hides the declarations required by expansion, including TCA's own macro. The bridge macro is qualified rather than renaming TCA's existing public API.
- **`@EditingPolicy` and `some EditingFeature`.** The separate policy declaration supplies the type-level lens coordinate needed to retain `.init(original)` without a record marker. An opaque `some Feature` hides the editing capability; it cannot satisfy `EditingFeature`. The generated nested alias keeps all generic machinery out of the property declaration.
- **`Update.Error.notFound`.** The actual domain update signature declares untyped `throws`, so its generated Failure is `any Error`. The compiler cannot infer bare `.notFound`. Selecting the concrete domain error explicitly preserves unrelated storage errors instead of falsely narrowing the operation's failure type.
- **`before: \.lists?.delete?.id`.** Canonical case projections are partial. Optional chaining composes these prisms accurately; omitting it would claim total fields on a sum type.

`Syntax Boundary Tests.swift` compiles rejected examples against this workspace's built modules and macro plugins for the conformance, macro-name, and opaque-capability boundaries. The untyped-error diagnostic was also observed in the actual workspace build. These limits are not simulated by alternate domain representations.

The bridge re-exports its canonical Operation algebra and the Reminders feature target re-exports its editing record dependency. This makes their public generated signatures visible under MemberImportVisibility without contradictory unused-public-import diagnostics. The hard error remains enabled; no diagnostic is disabled.

## Validation

Use `reminders-architecture.xcworkspace`, not the project alone. Every relevant package is included as a local workspace reference; manifests retain URL dependencies. All workspace packages declare platform minimums of 27.

The Reminders Architecture scheme covers the app, its views, experiment tests, Interface/Product macro consumers, and bridge tests. Feature Runtime Tests covers TCA runtime regressions; Feature Macro Tests covers TCA derivation. Validation results are recorded in README.md after the final run.
