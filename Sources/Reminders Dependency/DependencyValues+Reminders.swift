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
            list: .init(client: .init(unimplemented("\\.reminders.list.client", placeholder: List.Result(selection: .filter(.all), preference: Preference())))),
            retrieve: .init(client: .init(unimplemented("\\.reminders.retrieve.client", placeholder: nil))),
            start: .init(client: .init(unimplemented("\\.reminders.start.client", placeholder: nil))),
            create: .init(client: .init(unimplemented("\\.reminders.create.client", placeholder: false))),
            update: .init(client: .init(unimplemented("\\.reminders.update.client", placeholder: false))),
            toggle: .init(client: .init(unimplemented("\\.reminders.toggle.client", placeholder: nil))),
            delete: .init(client: .init(unimplemented("\\.reminders.delete.client"))),
            reorder: .init(client: .init(unimplemented("\\.reminders.reorder.client"))),
            deleteCompleted: .init(client: .init(unimplemented("\\.reminders.deleteCompleted.client"))),
            overview: .init(
                fetch: .init(client: .init(unimplemented("\\.reminders.overview.fetch.client", placeholder: Overview.Fetch.Result())))
            ),
            lists: .init(
                create: .init(client: .init(unimplemented("\\.reminders.lists.create.client"))),
                update: .init(client: .init(unimplemented("\\.reminders.lists.update.client", placeholder: false))),
                delete: .init(client: .init(unimplemented("\\.reminders.lists.delete.client"))),
                reorder: .init(client: .init(unimplemented("\\.reminders.lists.reorder.client")))
            ),
            tags: .init(
                create: .init(client: .init(unimplemented("\\.reminders.tags.create.client", placeholder: nil))),
                update: .init(client: .init(unimplemented("\\.reminders.tags.update.client", placeholder: nil))),
                delete: .init(client: .init(unimplemented("\\.reminders.tags.delete.client"))),
                list: .init(client: .init(unimplemented("\\.reminders.tags.list.client", placeholder: [])))
            ),
            preferences: .init(
                ordering: .init(client: .init(unimplemented("\\.reminders.preferences.ordering.client"))),
                toggleShowCompleted: .init(client: .init(unimplemented("\\.reminders.preferences.toggleShowCompleted.client")))
            )
        )
    }
}
