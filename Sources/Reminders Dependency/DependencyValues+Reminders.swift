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
            create: unimplemented("\\.reminders.create"),
            retrieve: unimplemented("\\.reminders.retrieve"),
            update: unimplemented("\\.reminders.update"),
            delete: unimplemented("\\.reminders.delete"),
            list: unimplemented("\\.reminders.list", placeholder: List.Result(selection: .filter(.all), preference: Preference())),
            reorder: unimplemented("\\.reminders.reorder"),
            complete: unimplemented("\\.reminders.complete"),
            reopen: unimplemented("\\.reminders.reopen"),
            deleteCompleted: unimplemented("\\.reminders.deleteCompleted"),
            overview: unimplemented("\\.reminders.overview", placeholder: Overview.Result()),
            lists: .init(
                create: unimplemented("\\.reminders.lists.create"),
                update: unimplemented("\\.reminders.lists.update"),
                delete: unimplemented("\\.reminders.lists.delete"),
                reorder: unimplemented("\\.reminders.lists.reorder")
            ),
            tags: .init(
                create: unimplemented("\\.reminders.tags.create"),
                update: unimplemented("\\.reminders.tags.update"),
                delete: unimplemented("\\.reminders.tags.delete"),
                list: unimplemented("\\.reminders.tags.list", placeholder: [])
            ),
            preferences: .init(
                update: unimplemented("\\.reminders.preferences.update")
            )
        )
    }
}
