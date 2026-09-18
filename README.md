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
| `Reminders` | Interface Macro | the domain, declared once as `@Interface` protocols: `create`, `read`, `observe`, `update`, `delete`, `lists`; the values they exchange (`Filter`, `Page`, `Summary`); the typed errors. `observe` takes a `read` request and yields its value on every change, so observation is a domain capability, not a storage one |
| `Reminders Dependency` | Dependencies | `DependencyValues.reminders`, the `testValue`, and the `Sendable` boundary |
| `Reminders SQL` | StructuredQueries | the records and the `Filter` predicate |
| `Reminders SQLite` | SQLiteData, GRDB | the schema, `Reminders.sqlite(database)`, the read requests resolved and tracked (`ValueObservation`), the bootstrap |
| `Reminders Sample` | — | two lists, three reminders |
| `Reminders Feature` | TCA26 | features nested under the interface operations they call: `Reminders.Feature` (root), `Read.Feature` (front screen), `Read.Page.Feature` (one page, a row edited in place), `Update.Feature` (the draft), `Lists.Create.Feature` (the sheet). No storage import: pages are `observe`d; failures live on `@StoreTaskID`s |
| `Reminders View` | SwiftUI | one universal view per feature (`Reminders.Read.SwiftUI`, …), one row view built from a value; nothing platform- or host-specific |
| `Reminders App` | | the universal app: `Reminders.Screen` (the navigation tree) and the live store. A platform-specific app is another target beside this one composing the same views |
| `Hosts/Reminders` | | `@main` |

What was cut: due dates, priorities, flags, notes, tags, search, smart lists, ordering and preferences, paging,
the completion grace period, app-storage restoration, the day clock, the sample generator, the PostgreSQL
placeholder, all styling and parity chrome, and the evidence.

Build and test with the `reminders.xcworkspace` scheme.
