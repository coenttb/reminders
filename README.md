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
| `Reminders` | Interface Macro | the domain, declared once as `@Interface` protocols: `create`, `read`, `update`, `delete`, `lists`; the values they exchange (`Filter`, `Page`, `Summary`); the typed errors |
| `Reminders Dependency` | Dependencies | `DependencyValues.reminders`, the `testValue`, and the `Sendable` boundary |
| `Reminders SQL` | StructuredQueries | the records and the `Filter` predicate |
| `Reminders SQLite` | SQLiteData | the schema, `Reminders.sqlite(database)`, the read requests as `FetchKeyRequest`s, the bootstrap |
| `Reminders Sample` | — | two lists, three reminders |
| `Reminders Feature` | TCA26 | the root, the front screen, one listing with a row edited in place, the list form sheet |
| `Reminders View` | SwiftUI | one view per feature, one row view built from a value |
| `Reminders App` | | `Reminders.Screen` (the navigation tree) and the live store |
| `Hosts/Reminders` | | `@main` |

What was cut: due dates, priorities, flags, notes, tags, search, smart lists, ordering and preferences, paging,
the completion grace period, app-storage restoration, the day clock, the sample generator, the PostgreSQL
placeholder, all styling and parity chrome, and the evidence.

Build and test with the `reminders.xcworkspace` scheme.
