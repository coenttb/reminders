# reminders-architecture

> The interface-to-feature integration uses shared interpretations of the existing domain.
> Application-specific navigation and editing policies are declared separately from operations.

The [Reminders](https://github.com/coenttb/reminders) app reduced to its architectural essence: every layer and
every kind of relationship between layers is kept, and each is cut to the smallest exemplar that still runs. It
exists to judge the structure of the layers above the domain — the features, the views, the app — without the
product surface in the way.

One flat package, one host, one workspace. The layers, bottom up:

| Target | Depends on | Holds |
|---|---|---|
| `List` | Tagged | `List<Element>` and its `Entry` (a list with its open count) |
| `Reminder` | List | the `Reminder` value |
| `Reminders` | Interface Macro | the domain, declared once as `@Interface` protocols: `create`, `read`, `update`, `delete`, `lists`; the values they exchange, each under its operation (`Read.Filter`, `Read.Value`, `Read.Page.Value`); the typed errors. An operation's `Value` is what it produces, its `Result` is how the arrow returns it: `read()` and `read(page:)` return streams of their `Value` (the UI follows them), `read(id)` returns the `Reminder` itself; `update.complete` is its own write |
| `Reminders Dependency` | Dependencies | `DependencyValues.reminders`, the `testValue`, and the `Sendable` boundary |
| `Reminders SQL` | StructuredQueries | the records and the `Filter` predicate |
| `Reminders SQLite` | SQLiteData, GRDB | the schema, `Reminders.sqlite(database)`, the read requests resolved and tracked (`ValueObservation`), the bootstrap |
| `Reminders Sample` | — | two lists, three reminders |
| `Reminders Feature` | TCA26, Interface ComposableArchitecture | the root `Reminders` conformance and relationship declarations for generic `Listing` and `Editing` interpretations. Features observe reads and send calls, no point reads: the front screen and a page's contents are `Observing` `read()` / `read(page:)`; the sheet is `Requesting` `lists.create`; writes (delete, complete, list delete) are `Reminders.Call`s carried by actions. No storage import; failures live on `@StoreTaskID`s |
| `Reminders SwiftUI` | SwiftUI | one universal view per feature (`Reminders.Read.View`, …), one row view built from a value, `Reminders.View` (the navigation tree) and the live store. A platform-specific app is another target beside this one composing the same views |
| `Hosts/Reminders` | | `@main` |

What was cut: due dates, priorities, flags, notes, tags, search, smart lists, ordering and preferences, paging,
the completion grace period, app-storage restoration, the day clock, the sample generator, the PostgreSQL
placeholder, all styling and parity chrome, and the evidence.

## Interface-type reuse

`@Interface` attaches `@Operations`, which derives one symbol per operation (`Reminders.Read.Run`, `Reminders.Read.Page.Run`; each operation is
its own `@Interface`, so its symbol is its `Run`) whose `Input` is the parameters as a value and which knows how its owner runs it. `@Interface` derives
the `Call` — the coproduct of the operations' inputs and the children's calls, `Hashable` and `Sendable` when the
inputs are — with its constructors, its builders and `run(owner, call)`. The layers above the domain write
against those, not against types of their own:

- **Input as draft.** `Reminders.Update.State` edits a `Reminder.Draft` and the sheet a
  `Reminders.Lists.Create.Input`; a one-field input reads as its field (`$store.request.title`), the editor state
  as its draft (`$store.title`, `store.completed.toggle()`).
- **Call as action.** The page's `Action` *is* `Reminders.Call`; the sheet's is `Reminders.Lists.Create.Call`. The root
  derives routes through `read.page` and `lists.create`; observation contributes no actions.
  Every call is run exactly once, by the selected feature's task lifetime. A scoped list
  command and a form submission retain their own outcomes rather than becoming root calls.
- **Sugar over the call.** `.delete(id)`, `.update.complete(id, done)`, `.lists.delete(id)` are the Call's own
  builders (children are static members); `store.delete(id)`, `store.update.complete(id, done)`,
  `store.send()` on the sheet are the same builders handing the call to `send`. Neither returns nor throws;
  the outcome is on the task id.
- **State the view sets.** `store.read.page = .init(.list(id))`, `store.editing = .init(reminder)`,
  `store.editing = nil`, `store.lists.create = .init(List<Reminder>.Draft())`, `store.dismiss()`. The editor has no
  actions: leaving is what writes (create a draft, update a changed row, drop a blank one).
- **Observing / Requesting** (swift-interface-composable-architecture): `Observing(reminders.read.page)`
  follows an operation's stream for its request; `Requesting(reminders.lists.create)`
  composes an input and sends any call of its interface, dismissing on success. Storage mints identity:
  `create` takes a `Draft`.

Build and test with the **Reminders Architecture** scheme in `reminders-architecture.xcworkspace`,
on macOS 27 or an iOS 27 simulator. The workspace resolves
`swift-interface`, `swift-operation`, `swift-product`, `swift-coproduct`, `swift-optic`, `swift-either`,
`swift-interface-composable-architecture` and `TCA26` (branch `interface-calls`) from sibling checkouts.


## Interface integration

Open `reminders-architecture.xcworkspace` and select **Reminders Architecture**. The shared
scheme builds the app, all eight experiment test targets, Interface and Product macro tests,
and the TCA bridge tests. Institute packages resolve from workspace references; manifests retain URLs.

Declare `@Interface` once on each domain. It attaches `@Operations` to the semantic
protocol and composes the product, coproduct, structural capabilities, optics, and
elimination macros. Child inclusion maps are properties so both `.update.complete(...)`
and `store.update.complete(...)` use the canonical Call. Primary implementation closures
are unlabeled, including when sibling operations or children follow them.

`Observing` retains an operation's stream and follows its values. `Requesting` executes a
request, exposes its task outcome, and dismisses on success. Sending a Call does not
subscribe to a returned stream. Canonical calls need no consumer CasePathable adoption;
the domain macro does not import the UI framework.

The generated embedding represents `Call -> Result`; child navigation composes a child
injection with that function. It is emitted beside the coproduct, with a type alias under
`Call`, so Swift 6.4 can lower each attached extension macro on its own type. It does not
add another action representation. Explicit conformance to the nested semantic protocol
remains part of the declaration; macros cannot announce that arbitrary nested conformance.

## Derived interpretations and explicit policies

The existing domain types receive their interpretations in separate source files. No handwritten
State, Action, operation-symbol, or structural-descriptor declarations are needed:

```swift
@Interface_ComposableArchitecture.Feature
extension Reminders: FeatureProtocol {
    public var body: some Feature {
        Features {
            Child(\.read)
            Child(\.lists)
        }
        .dismiss(\.read.page, matching: \.filter.list, before: \.lists?.delete?.id)
    }
}
```

Read composes `Observing(self)` and `Presenting(\.page)`. Lists presents its create form;
that form uses `Requesting(self)`. The page selects its rows, ancestor commands, editing
policy and deletion prism through `Listing`. Update reuses the ancestor's editing policy.
Required children project as scoped stores sharing their existing state and task lifetime.

`@EditingPolicy` derives the draft coordinate from the selected `\.draft` lens. Neither
Reminder nor the page result adopts a bridge-specific marker conformance. The editing
policy returns `some EditingFeature`, retaining the capabilities that a listing needs
without exposing a concrete implementation. Create/update/delete receive the existing
operation values. Blank handling and ignored update failures remain explicit choices.

| Interpretation | Canonical algebra consumed | Policy |
|---|---|---|
| InterfaceFeature | Existing call coproduct and interpreter | Execute commands, record task outcome |
| Executing | Indexed input and output | Execute a request, retain its result |
| Observing | Sequence-valued operation | Follow values; replace observation when the request changes |
| Requesting | Canonical input and calls | Submit, stay on failure, dismiss on success |
| Editing | Selected writable draft lens and operation arrows | Commit on dismount, with explicit blank/error policies |
| Listing | Selected rows projection, canonical calls, editing capability | Observe rows, overlay an edit, execute writes and present editing |

Compositions bind the actual domain instance in the feature environment. A standalone page
or editor receives it with `.interface(reminders)`; there is no global lookup. Root and
scoped deletion share the same matching rule but retain their original task/error ownership.
The domain module still imports no TCA or SwiftUI framework.

See [FEATURE-SYNTAX.md](FEATURE-SYNTAX.md) for the file-by-file implementation, algebraic
responsibilities, and compiler-backed deviations from the aspirational syntax at b689cff.

### Derivation boundary

Product, sum, and lens relationships support these generic interpretations. They do not
choose navigation, blank-value handling, field renderers, or initial inputs. Those remain
explicit domain or application decisions. Stateful TCA interpretations require Copyable
inputs even though the underlying operation algebra supports wider ownership semantics.
The operation runtime erases thrown errors, and the Reminders update signature itself is
untyped: selecting `Update.Error.notFound` does not hide other storage errors.

## SwiftUI interpretations

The views declare their domain once with `@View(Domain.self)`. The bridge derives
store injection and input construction. Presentation binds directly to existing child
coordinates: `$store.read.page` and `$store.lists.create`. `EditingRows(store)` renders
canonical listing rows with their selected editor; `.focusOnPresentation()` keeps focus
local to the field. Layout, labels, draft defaults, navigation style, and submission
policies remain explicit.

See [SWIFTUI-SYNTAX.md](SWIFTUI-SYNTAX.md) for the design checkpoint, implementation
inventory and validation. Automated tests use Swift Testing through the
**Reminders Architecture** workspace scheme. Simulator UI checks are manual.

## Validation

Open **reminders-architecture.xcworkspace**. All relevant local packages are included;
package manifests use URL dependencies and all workspace package minimums are 27.
MemberImportVisibility is enforced as a hard error for the integration consumers.

The macOS workspace suite uses Swift Testing. Build the `Reminders` scheme for
simulator or device validation; UI interaction is checked manually. Earlier device
validation and archived screenshots describe their respective checkpoints.
The naming rule and validation history are recorded in
[SWIFTUI-SYNTAX.md](SWIFTUI-SYNTAX.md).

The preceding Feature checkpoint's validation—including the focused TCA runtime and
macro suites and both simulator architectures—is preserved in
[VALIDATION.md](VALIDATION.md).
