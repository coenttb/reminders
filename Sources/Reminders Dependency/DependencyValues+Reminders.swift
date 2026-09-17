public import Dependencies
import Models
public import Reminders

extension DependencyValues {
    public var reminders: Reminders {
        get { self[Reminders.self] }
        set { self[Reminders.self] = newValue }
    }
}

extension Reminders: TestDependencyKey {
    public static var testValue: Reminders {
        Self(
            create: .init(client: .init(unimplemented("\\.reminders.create.client"))),
            retrieve: .init(client: .init(unimplemented("\\.reminders.retrieve.client"))),
            update: .init(client: .init(unimplemented("\\.reminders.update.client"))),
            delete: .init(client: .init(unimplemented("\\.reminders.delete.client"))),
            list: .init(client: .init(unimplemented("\\.reminders.list.client", placeholder: List.Result(selection: .filter(.all), preference: Preference())))),
            reorder: .init(client: .init(unimplemented("\\.reminders.reorder.client"))),
            complete: .init(client: .init(unimplemented("\\.reminders.complete.client"))),
            reopen: .init(client: .init(unimplemented("\\.reminders.reopen.client"))),
            deleteCompleted: .init(client: .init(unimplemented("\\.reminders.deleteCompleted.client"))),
            overview: .init(client: .init(unimplemented("\\.reminders.overview.client", placeholder: Overview.Result()))),
            lists: .init(product: .init(
                create: unimplemented("\\.reminders.lists.create"),
                update: unimplemented("\\.reminders.lists.update"),
                delete: unimplemented("\\.reminders.lists.delete"),
                reorder: unimplemented("\\.reminders.lists.reorder")
            )),
            tags: .init(
                create: .init(client: .init(unimplemented("\\.reminders.tags.create.client"))),
                update: .init(client: .init(unimplemented("\\.reminders.tags.update.client"))),
                delete: .init(client: .init(unimplemented("\\.reminders.tags.delete.client"))),
                list: .init(client: .init(unimplemented("\\.reminders.tags.list.client", placeholder: [])))
            ),
            preferences: .init(
                update: .init(client: .init(unimplemented("\\.reminders.preferences.update.client")))
            )
        )
    }
}
