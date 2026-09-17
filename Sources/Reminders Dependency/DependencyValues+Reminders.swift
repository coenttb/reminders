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
            list: unimplemented("\\.reminders.list", placeholder: Page(selection: .filter(.all), preference: Preference())),
            reorder: unimplemented("\\.reminders.reorder"),
            complete: unimplemented("\\.reminders.complete"),
            reopen: unimplemented("\\.reminders.reopen"),
            deleteCompleted: unimplemented("\\.reminders.deleteCompleted"),
            overview: unimplemented("\\.reminders.overview", placeholder: Summary()),
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

// swift-dependencies requires Sendable values; the interfaces themselves carry no
// Sendable requirement, so the boundary is asserted here, not in Reminders.
extension Reminders: @unchecked Sendable {}
extension Reminders.Lists: @unchecked Sendable {}
extension Reminders.Tags: @unchecked Sendable {}
extension Reminders.Preferences: @unchecked Sendable {}
