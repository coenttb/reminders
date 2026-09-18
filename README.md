# reminders-architecture

The [Reminders](https://github.com/coenttb/reminders) app reduced to its architectural essence: every layer and
every kind of relationship between layers is kept, and each is cut to the smallest exemplar that still runs. It
exists to judge the structure of the layers above the domain — the features, the views, the app — without the
product surface in the way.

One flat package, one host, one workspace. The layers, bottom up:

| Target | Depends on | Holds |
|---|---|---|
| `Models` | Tagged | `List<Element>` and its `Entry` (a list with its open count) |
| `Reminder` | Models | the `Reminder` value |
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

The `@Interface` macro derives, for every operation, a `Request` (its parameters as a value) and, for every
interface, a `Call` (the coproduct of its operations' requests, `Hashable` and `Sendable` when the requests are)
together with an interpreter `reminders(call)`. The layers above the domain reuse those types instead of
declaring their own:

- **Request as draft.** `Reminders.Update.Feature.State` holds `Reminders.Update.Request` — the very value
  `update` is called with — and the view binds `$store.request.reminder.title`. The list sheet holds
  `Reminders.Lists.Create.Request` the same way.
- **Call as action.** Every feature's `Action` *is* `Reminders.Call` (the sheet's is `Reminders.Lists.Call`,
  embedded at `\.lists`); there are no bespoke action enums. `.calling(reminders, id: \.writes)` runs each as a
  task. `store.send(.update.complete(id, done))` and `store.update.complete(id, done)` are sugar over the same
  call; neither returns nor throws — the outcome is read from `writes`. Everything that is not a call is state
  the view sets on the store: `store.listing = .init(page: .list(id))`, `store.editing = .init(reminder)`,
  `store.editing = nil`, `store.dismiss()`. Writing the draft is the editor's `onDismount`.
- **Observing / Requesting** from `swift-interface-composable-architecture` are the two generic features over an
  operation symbol: `Observing<Reminders.Read.Operations.Page> { reminders.read($0) }` keeps a request's
  value current; `Requesting { try await reminders.lists.create($0) }` composes a request and sends it whole.
  The arrows themselves live in `Reminders.Product` (the `@Product` of the interface's request-typed model);
  features call the interface's witnesses, never the product.

Build and test with the `reminders.xcworkspace` scheme, destination iPhone 17. The workspace resolves
`swift-interface`, `swift-operation` and `swift-interface-composable-architecture` from sibling checkouts.
