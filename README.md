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
| `Reminders SwiftUI` | SwiftUI | one universal view per feature (`Reminders.Read.SwiftUI`, …), one row view built from a value, `Reminders.Screen` (the navigation tree) and the live store. A platform-specific app is another target beside this one composing the same views |
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
- **Observing / Requesting** (swift-interface-composable-architecture): `Observing<Reminders.Read.Page.Run>(reminders.read.page)`
  follows an operation's stream for its request; `Requesting<Reminders.Lists.Create.Run>(reminders.lists.create)`
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
subscribe to a returned stream. Framework-specific CasePathable adoption remains in the
integration module; the domain macro does not import the UI framework.

The generated embedding represents `Call -> Result`; child navigation composes a child
injection with that function. It is emitted beside the coproduct, with a type alias under
`Call`, so Swift 6.4 can lower each attached extension macro on its own type. It does not
add another action representation. Explicit conformance to the nested semantic protocol
remains part of the declaration; macros cannot announce that arbitrary nested conformance.

## Derived interpretations and explicit policies

The domain keeps its original operation types. `Reminders.Read.Page`, `Reminders.Lists.Create`,
and `Reminders.Update` adopt FeatureProtocol in the integration target, aliasing the existing
Listing, Requesting, and Editing state. There are no additional Page or Editing domain types.

`@Interface` emits canonical typed child projections under `Structure`. The bridge's
`@FeatureComposition` selects required children, optional presentations, and observation:

```swift
@FeatureComposition(
    .required(Reminders.Structure.read.self),
    .required(Reminders.Structure.lists.self),
    calls: Reminders.Call.self
)
extension Reminders {}
```

It derives State as the product of selected child states and Action as their routed sum,
reusing canonical calls. State and Action are aliases to the generated interpretation;
there are no handwritten copies. Read owns its optional page; Lists owns optional Create.
Required children project as scoped stores, so `store.lists.delete(id)` and
`store.lists.create = .init(...)` share the existing child state and lifetime.

| Interpretation | Canonical algebra consumed | Policy |
|---|---|---|
| `InterfaceFeature<Call>` | Existing coproduct and interpreter | Execute commands, record task outcome |
| `Executing<Symbol>` | Indexed Input and Output | Execute a request, retain the last successful output |
| `Observing<Symbol>` | Sequence-valued operation | Follow values; replace observation when the request changes |
| `Requesting<Symbol>` | Canonical input and calls | Submit, stay on failure, dismiss on success |
| `Editing<Record>` | Writable draft projection and supplied operation arrows | Apply explicit blank and update-failure policies on dismount |
| `Listing<Symbol, Call>` | Query result rows, canonical calls, draft lens | Observe rows, overlay an edit, route writes, present editing |

Any existing interface Call can be interpreted with `Reminders.Call.feature(reminders)`.
Any eligible operation can use `Symbol.executing(owner)`, `.observing(owner)`, or
`.requesting(owner)`. These interpreters do not need a bespoke feature or another domain
model. The generic parameters retain the input/output/call types; no Any payload schema
or handwritten command enum is introduced.

Reminders declares its remaining meaning in `Reminders+Interpretations.swift`:

- `Reminder.draft` is a writable projection preserving identity and creation time.
  `EditableRecord` supplies that witness to the editing interpreter. Its lens laws are tested.
- A page query's existing Value projects `rows` through `ListingValue`.
- Create, update, and delete are the existing callable operations, passed directly.
- Blank new drafts are discarded; blank existing rows are deleted. This is an explicit
  application policy, not a mathematical consequence of an operation signature.
- Only update's notFound error is ignored, for the disappearance race.
- The canonical delete case identifies which displayed edit to dismiss.

The root's custom body is in a separate source conformance extension. Separating it from
the composition declaration avoids Swift 6.4's macro lookup cycle for a source body's
inherited feature builder. Its remaining custom policy closes a list's page before deletion.

The composition macro attaches TCA's @Feature to its generated implementation. Generated
types declare conformances directly, while attached macros derive their witnesses; no
conformance relies on nested extension-macro lowering. Task identifiers and scopes belong
to this interpretation, not the domain. Compositions publish their actual owner in the
feature environment; WithInterface lets the page reuse its ancestor's editing capabilities
without obtaining another implementation from a global dependency.

Views retain their existing names and `store.update.complete(...)`, `store.delete(...)`,
and `store.send()` syntax. The operation namespace still requires qualifying TCA's Update
inside the root. The domain module imports no TCA or SwiftUI framework.

### Derivation boundary

A default executable feature follows from the existing operation algebra. An arbitrary
polished UI does not follow from it: field editors, initial input values, display semantics,
and navigation choices need witnesses or policy. No renderer is inferred from parameter
names, and no generic form for an arbitrary Swift type is promised. The reminders UI is
one explicit rendering of the shared interpretations.

`Operation.Operable.run` currently erases the static throws sort to `any Error`; execution
retains the concrete error in StoreTaskID, but does not falsely advertise an indexed failure
value that this runtime contract cannot guarantee. Noncopyable input execution in TCA state
is unsupported: these stateful interpretations require Copyable, while the underlying
operation algebra retains its wider ownership support.

A root macro cannot attach arbitrary conformances to imported child types, and Swift 6.4
cannot lower nested extension macros emitted inside another macro's extension output.
Existing domain types therefore receive their feature interpretations in explicit source
extensions. Generated types declare their own conformances and attach the owning macros
for member derivation. No global state or unsafe conformance simulates extension storage.

## Current validation

The exact **Reminders Architecture** workspace scheme builds and passes **108 tests
across 11 targets on macOS 27**, with no failures, skips, or runtime warnings. This
includes nested presentation and dismissal, scoped property sending and error ownership,
root versus child execution routes, actionless observation, editing policies, and the
domain's compiled macro consumers. The workspace's **Feature Macro Tests** scheme also
passes **52 TCA macro tests**, including explicit-conformance generation.
MemberImportVisibility remains a hard error. All affected packages resolve through the
workspace, and package manifests use URL dependencies exclusively.

The same workspace builds the app for iOS 27 Simulator.
