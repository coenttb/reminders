# Domain-first SwiftUI syntax

## Design checkpoint

Behavioral baseline: Reminders Architecture `5d82f3e`, Interface `939e57c`,
Interface–TCA bridge `49a8583`, TCA26 `d57de58`.

This is the aspirational source specification. It is intentionally committed before
implementing supporting APIs or running builds/tests. Compilation is not claimed at
this checkpoint. Keep the design literal unless actual compiler or semantic evidence
requires a documented deviation.

## File inventory

| File | Machinery removed | Aspirational declaration | Explicit policy retained |
| --- | --- | --- | --- |
| `Reminders.Screen.swift` | Store storage/initializer; local bindable aliases; repeated state/action scope selection | `@View(Reminders.self)` and `$store.read.page` / `$store.lists.create` as presentation bindings | NavigationStack versus sheet, titles, toolbar, error precedence, initial list draft |
| `Reminders.Read.SwiftUI.swift` | Store storage/initializer | `@View(Reminders.self)` | This summary needs the root capabilities to present pages and delete lists; counts, labels, row actions remain explicit |
| `Reminders.Read.Page.SwiftUI.swift` | Store storage/initializer; row/editor identity branching; duplicate new-editor branch; manual actionless scope; cross-view focus plumbing | `@View(Reminders.Read.Page.self)`, one `title` input, `EditingRows(store) { row } editor: { editor }` | Row rendering, canonical complete/delete calls, starting an edit, blank-space gesture, explicit list for a new draft, error appearance |
| `Reminders.Update.SwiftUI.swift` | Store storage/initializer; parent-owned FocusState binding | `@View(Reminders.Update.self)`, `.focusOnPresentation()` | Completion toggle, text field, focus on editor presentation, submit dismisses and therefore commits through the feature lifetime |
| `Reminders.Lists.Create.SwiftUI.swift` | Store storage/initializer | `@View(Reminders.Lists.Create.self)` | Field renderer, cancel/submit, blank and in-flight validation, error section |
| `Reminder.Row.SwiftUI.swift` | Public initializer assigning each private field | `@View` over the existing value and intent closure inputs | It is a value renderer, not another store or feature; button labels, icons, spacing and swipe deletion stay explicit |
| `StoreOf<Reminders>.swift` → `Reminders.Live.swift` | Stale mechanical filename and redundant concrete State spelling | `Store(initialState: .init()) { reminders }` | Database initialization, debug seeding, dependency selection, root lifetime and failure policy are composition-root decisions, not derivable UI plumbing |

## Responsibilities and algebra

### View inputs

A view is a rendering function of a product of inputs. The bridge's proposed `@View`
member macro derives the public construction function for explicit stored inputs.
With a domain argument it additionally injects a bindable store of that existing
feature. It does not infer layout, derive feature state, copy domain data, synthesize
business actions, or change lifetime. Existing SwiftUI View conformances remain explicit.
The existing Product macro derives protocol products, not constructors of arbitrary
view structs, so it is not an interchangeable operation.

A store must still be passed explicitly at the composition boundary. There is no
ambient/global store lookup. Additional fields such as the page title remain declared
and supplied once. The macro must reject unsupported inputs clearly rather than
silently omit them or guess wrapper initialization semantics.

### Presented children

Required children compose product projections; optional children add a partial
projection and an existing action injection. These coordinates already belong to the
Feature derivation. `$store.read.page` should reuse them to yield the optional scoped
store binding consumed by SwiftUI navigation. Clearing it clears the existing state
and ends the existing lifetime; it must not construct a replacement store or duplicate
state. Ordinary writable field bindings must keep working.

The source body chooses which children are required/presented only once. Extend that
same derivation with typed binding projections, reusing TCA's scope implementation.
Do not scan another package's source or reconstruct its operation algebra.

### Editing rows

A listing already knows its rows, row identity, selected draft lens, and optional editor.
`EditingRows` renders the existing row product with its selected editor substituted by
identity, and renders a new draft once when no original record exists. It consumes the
existing Listing state and actionless child scope; it stores no parallel row model.
It receives explicit value/editor rendering functions and does not choose controls,
layout, command semantics, or create a feature. Switching editors must preserve commit
on dismount and focus the new editor even if SwiftUI reuses a view identity.

### Focus and presentation

Focus is an explicit UI policy. A reusable modifier owns its local FocusState and
requests focus when its text field is presented. It cannot select navigation, commit,
or imply feature lifetime. Editor identity must ensure switching rows updates focus.
Submit and Done continue dismissing through the existing feature/state contract.

## Implementation scope and validation requirements

Prefer the existing Interface–TCA bridge target/plugin for view adaptation and derived
projection metadata. Reuse TCA binding/scoping APIs and make TCA changes only if their
public capabilities are insufficient. No new package is justified by this design.

Complete all static implementation and meaningful regression tests before builds.
Then use only `reminders-architecture.xcworkspace` for resolution/builds/tests, with URL
package dependencies, minimum platforms 27 and hard MemberImportVisibility. Verify
presentation bindings, row/editor identity, state sharing, action routing, and dismissal
lifetimes; retain existing feature/SQL integration tests. Build and run the actual app
on an iOS 27 simulator and exercise navigation, list/reminder creation, editing,
completion, deletion and dismissal, recording screenshots and observations.

Record implementation results, compiler-backed deviations, exact validation and final
commit identifiers below after implementation. This checkpoint is a design, not a
successful-build assertion.

## Implemented result

The design checkpoint is `335364a`. All seven file entries above are implemented with
the proposed syntax. No compiler-driven call-site deviation has been necessary.
`@View` remains solely an input derivation; the existing source View conformances
continue to express which types render UI. The macro uses the existing bridge plugin.

`ViewStore<Domain>` retains the injected store reference and exposes `ViewBindings`.
The existing composition derivation emits a typed `Bindings` coordinate map beside
its store projection, consuming the same required/presented selections. These maps
store only the original store reference and delegate to TCA scopes; no domain state,
call representation, or navigation state is duplicated. Writable fields use SwiftUI's
bindable key-path projection, not get/set closure bindings.

`EditingRows` uses the canonical listing and actionless editor. Row identity decides
substitution. It retains the original list's ordering and renders a new draft once.
`focusOnPresentation` owns its local FocusState and activates when its field appears.
The completion buttons now state their accessible action and reminder title explicitly;
this improves accessibility while retaining their visual appearance.

The live composition root retains its database bootstrap, debug-seeding and failure
policy. These are actual environment choices and cannot be inferred from a type's
product/sum/lens structure. Existing labels, layout, navigation style, draft defaults,
error placement and submission conditions remain explicit for the same reason.

## Validation evidence

The final macOS run passed 128 tests (129 executions), with zero failures,
skips or runtime warnings: `Test-Reminders Architecture-2026.09.20_00-20-19-+0200.xcresult`
under `/tmp/institute-reminders-derived/Logs/Test`. Coverage includes nested presentation
bindings, canonical request submission, independent presentation dismissal, ordinary
field writes, supplied input construction and escaping closures. Compiler fixtures
also verify diagnostics for unsupported property-wrapper inputs and competing initializers.

The exact workspace also contains the `Reminders UI Tests` scheme and native UI test
target. Its end-to-end flow exercises real navigation, cancel/submit, creation, completion,
editing and Return submission, blank draft discard, switching editor identity, relaunch
persistence and deletion. The test is configured to retain screenshot and accessibility hierarchy attachments.
The simulator test target compiled successfully, but its UI flow did not execute: the
existing simulator was unresponsive and the isolated replacement was still booting.
No successful simulator interaction or screenshot validation is claimed.

On September 20, 2026, the user validated the current code on their iPhone and instructed
that it be considered working and committed as a checkpoint. That device confirmation
is the accepted runtime validation for this checkpoint; further simulator work was
stopped. The reusable UI-test scheme remains available for a later simulator run.
