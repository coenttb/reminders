# Minimal Reminders stack: implementation

The static design is preserved in checkpoint `bb74c26`. The subsequent implementation
uses the existing packages in `reminders-architecture.xcworkspace`; no new package,
path dependency, or independently maintained domain/session model was introduced.

## Implemented derivations

| Package / target | Responsibility |
| --- | --- |
| swift-product / Product Macro | `@Memberwise` derives assigning constructors; `@Draft` selects a product complement, attaches `@Memberwise` to its draft, and derives its writable lens and reconstruction initializer. |
| swift-interface / Interface Macro | `@Interface(.sendable)` derives checked sending interfaces through the canonical Product macro. Primary `Request` aliases the canonical operation input. Factory construction follows canonical operations and children. |
| swift-interface / Interface Dependencies | Optional integration target containing `@Unimplemented(streams: .finished)`. It supplies reporting test implementations without importing Dependencies into the domain target. |
| swift-operation / Operation Macro Core | Canonical call-to-input extraction and unary field projection let editing consume the selected deletion operation without guessing its spelling. |
| swift-interface-composable-architecture | `Children`, compact `Listing` policy selection, explicit editing lifecycle, binding-preserving `@View` initializers, `Editing.Rows`, and `Tasks.Failure`. |
| swift-standard-library-extensions | Async-sequence adaptation preserving values, errors, completion, and upstream cancellation. |

Interface factory construction is independent of sendability. Generated closures
preserve typed throws and asyncness; generic output handling supports noncopyable
values. The test factory reports each unimplemented invocation. It finishes the
explicitly selected stream shapes, returns Void, or throws its placeholder error
where the declared error permits it. Arbitrary nonthrowing results and concrete
error types require an explicit test implementation; invoking their unimplemented
fallback terminates with an explanatory message rather than fabricating a value.

## Feature and view boundaries

The page retains:

```swift
Listing(self, rows: \.rows, editing: \Reminders.editing)
```

The root `Editing(...)` policy supplies `commit: .dismiss` and `discard: .delete`.
Observation returns original rows. `Editing.Rows` alone selects whether to show
a row or its bound draft editor, and accepts `Reminder.View.Row.Editor.init`.
Ordinary sending callbacks remain closures. Full `Reminder.View` and its compact
row editor consume the same canonical draft; the current page uses inline editing.

Deleting a matching record or its containing list marks the existing editing
session discarded before removing it. Dismount snapshots share that outcome, so
they cannot subsequently start a commit. This does not retroactively undo a write
that has already started. Normal dismissal commits through the owning page's task
identity, where genuine update failures remain observable while that page exists.

`blank: .discardNewDeleteExisting(\.isBlank)` remains an explicit application rule:
an untouched new draft is discarded, while clearing an existing title deletes its
record. Blanket suppression of update-not-found failures has been removed.

## Small syntax differences and remaining work

List creation uses `.init(.init())`: the outer initializer creates request state,
and the inner initializer supplies its draft. A generic request cannot infer that
an arbitrary input type has a default constructor. No additional default-value
protocol was introduced solely to remove that argument.

Pass `{ editing.dismiss() }` for a zero-argument callback. The dismissal method's
source-location parameters have defaults, but a method reference retains them.

SQL record declarations and conversion maps still repeat domain fields. This is
unresolved duplication, not a claim that persistence projection is finished.
A macro on a storage wrapper cannot extend the external domain type, and an
extension macro nested inside another macro's extension output cannot supply the
required table conformance. Removing these adapters needs a legal composition
with the actual table derivation; the implementation does not hide that constraint
behind a hypothetical storage macro.

## Validation

All implementation was completed statically before builds and tests. Validation
used this exact workspace with `/tmp/institute-reminders-derived` as DerivedData:

- `Reminders Architecture`, macOS: workspace tests passed, with no unexpected
  failures. The result reports 142 tests and one intentional known-issue assertion
  verifying that an unimplemented test dependency reports its invocation.
- `Reminders`, generic iOS Simulator: app build succeeded.
- iPhone 17 simulator: overview/list navigation, existing row rendering, focused
  inline creation, and blank-draft dismissal passed without modifying existing records.

Coverage includes draft lens laws and defaults, checked sending, typed errors,
noncopyable factory results, binding storage, deletion/discard lifecycle, visible
update failures, and stream cancellation. The workspace retains platform minimum
27, URL-based dependencies, and explicit imports for MemberImportVisibility.

See the subsequent [implementation review](IMPLEMENTATION-REVIEW.md) for naming and complexity changes.
