# Reminders

A Reminders app used as a proof of concept for `@Interface`
([swift-interface](https://github.com/swift-institute/swift-interface)): the domain is declared once, as a
protocol with ordinary method signatures.

```swift
@Interface
public struct Lists: Lists.Interface {
    public protocol Interface {
        func create(_ list: Models.List<Reminder>) async throws
        func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) async throws
        func reorder(_ ids: [Models.List<Reminder>.ID]) async throws
    }
}
```

From that one declaration the macro derives a value you construct from closures and call as methods, with the
labels intact:

```swift
let lists = Reminders.Lists(
    create: { request in try await database.insert(request.list) },
    delete: { request in try await database.delete(request.id, replacement: request.replacement) },
    reorder: { request in try await database.reorder(request.ids) }
)

try await lists.delete(id, replacement: inbox)
```

and, for the same operations, a `Call` coproduct with prisms, folds and an exhaustive eliminator:

```swift
let call = Reminders.Lists.Call.delete(id, replacement: inbox)

let eliminate = Reminders.Lists.Call.Eliminator<String>(
    create:  { "create \($0.input.list.title)" },
    delete:  { "delete \($0.input.id)" },
    reorder: { "reorder \($0.input.ids.count)" }
)
```

Interfaces compose by property: [`Reminders`](Sources/Reminders/Reminders.swift) is itself an `@Interface`
over `create`, `read`, `update`, `delete`, `lists` and `tags`, so call sites read
`reminders.update.reorder(ids, in: filter)`.

The app layer builds on [TCA26](https://github.com/pointfreeco/TCA26) (unreleased), resolved as a URL dependency
in `Package.swift`; the `Sources/Reminders` domain module does not depend on it.
