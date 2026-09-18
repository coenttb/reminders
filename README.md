# reminders-architecture

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
| `Reminders Feature` | TCA26, Interface ComposableArchitecture | `Reminders.Feature` (root), `Read.Page.Feature` (one page, a row edited in place), `Update.Feature` (the draft, written when the editor leaves). Features observe reads and send calls, no point reads: the front screen and a page's contents are `Observing` `read()` / `read(page:)`; the sheet is `Requesting` `lists.create`; writes (delete, complete, list delete) are `Reminders.Call`s carried by actions. No storage import; failures live on `@StoreTaskID`s |
| `Reminders SwiftUI` | SwiftUI | one universal view per feature (`Reminders.Read.SwiftUI`, …), one row view built from a value, `Reminders.Screen` (the navigation tree) and the live store. A platform-specific app is another target beside this one composing the same views |
| `Hosts/Reminders` | | `@main` |

What was cut: due dates, priorities, flags, notes, tags, search, smart lists, ordering and preferences, paging,
the completion grace period, app-storage restoration, the day clock, the sample generator, the PostgreSQL
placeholder, all styling and parity chrome, and the evidence.

## Interface-type reuse

`@Operations` derives one symbol per operation (`Reminders.Read.Run`, `Reminders.Read.Page.Run`; each operation is
its own `@Interface`, so its symbol is its `Run`) whose `Input` is the parameters as a value and which knows how its owner runs it. `@Interface` derives
the `Call` — the coproduct of the operations' inputs and the children's calls, `Hashable` and `Sendable` when the
inputs are — with its constructors, its builders and `run(owner, call)`. The layers above the domain write
against those, not against types of their own:

- **Input as draft.** `Reminders.Update.Feature.State` edits a `Reminder.Draft` and the sheet a
  `Reminders.Lists.Create.Input`; a one-field input reads as its field (`$store.request.title`), the editor state
  as its draft (`$store.title`, `store.completed.toggle()`).
- **Call as action.** The page's `Action` *is* `Reminders.Call`; the sheet's is `Reminders.Lists.Call`. The root
  composes them (`case call(Reminders.Call)`, `case listing(...)`, `case destination(...)`) so that every call
  is run exactly once, by the feature whose task id carries its outcome: `.calling(reminders, id: \.writes)`
  on the page, `.calling(\.call, reminders, id: \.writes)` at the root.
- **Sugar over the call.** `.delete(id)`, `.update.complete(id, done)`, `.lists.delete(id)` are the Call's own
  builders (children are static members); `store.delete(id)`, `store.update.complete(id, done)`,
  `store.create(store.request)` are the same builders handing the call to `send`. Neither returns nor throws;
  the outcome is on the task id.
- **State the view sets.** `store.listing = .init(page: .list(id))`, `store.editing = .init(reminder)`,
  `store.editing = nil`, `store.destination = .init(.init(.init()))`, `store.dismiss()`. The editor has no
  actions: leaving is what writes (create a draft, update a changed row, drop a blank one).
- **Observing / Requesting** (swift-interface-composable-architecture): `Observing<Reminders.Read.Page.Run>(reminders.read.page)`
  follows an operation's stream for its request; `Requesting<Reminders.Lists.Create.Run>(\.reminders.lists.create)`
  composes an input and sends any call of its interface, dismissing on success. Storage mints identity:
  `create` takes a `Draft`.

Build and test with the `reminders.xcworkspace` scheme, destination iPhone 17. The workspace resolves
`swift-interface`, `swift-operation`, `swift-product`, `swift-coproduct`, `swift-optic`, `swift-either`,
`swift-interface-composable-architecture` and `TCA26` (branch `interface-calls`) from sibling checkouts.
