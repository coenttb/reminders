public import Dependencies
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
            create: .init(unimplemented("\\.reminders.create")),
            read: .init(
                unimplemented("\\.reminders.read", placeholder: Summary()),
                today: unimplemented("\\.reminders.read(today:)", placeholder: Summary()),
                id: unimplemented("\\.reminders.read(id)"),
                page: unimplemented("\\.reminders.read(page:)", placeholder: Page()),
                search: unimplemented("\\.reminders.read(search:)", placeholder: Page()),
                preference: unimplemented("\\.reminders.read.preference", placeholder: Preference(ordering: .dueDate, showCompleted: false))
            ),
            update: .init(
                unimplemented("\\.reminders.update"),
                recover: unimplemented("\\.reminders.update.recover"),
                order: unimplemented("\\.reminders.update.order"),
                turn: unimplemented("\\.reminders.update.turn"),
                show: unimplemented("\\.reminders.update.show"),
                reorder: unimplemented("\\.reminders.update.reorder")
            ),
            delete: .init(
                unimplemented("\\.reminders.delete"),
                permanently: unimplemented("\\.reminders.delete.permanently"),
                expired: unimplemented("\\.reminders.delete.expired"),
                completed: .init(
                    in: unimplemented("\\.reminders.delete.completed(in:)"),
                    matching: unimplemented("\\.reminders.delete.completed(matching:)")
                )
            ),
            lists: .init(
                create: unimplemented("\\.reminders.lists.create"),
                update: unimplemented("\\.reminders.lists.update"),
                delete: unimplemented("\\.reminders.lists.delete"),
                reorder: unimplemented("\\.reminders.lists.reorder")
            ),
            tags: .init(
                create: unimplemented("\\.reminders.tags.create"),
                rename: unimplemented("\\.reminders.tags.rename"),
                delete: unimplemented("\\.reminders.tags.delete"),
                suggest: unimplemented("\\.reminders.tags.suggest", placeholder: [])
            )
        )
    }
}

// swift-dependencies requires Sendable values; the interfaces themselves carry no
// Sendable requirement, so the boundary is asserted here, not in Reminders.
extension Reminders: @unchecked Sendable {}
extension Reminders.Create: @unchecked Sendable {}
extension Reminders.Read: @unchecked Sendable {}
extension Reminders.Update: @unchecked Sendable {}
extension Reminders.Delete: @unchecked Sendable {}
extension Reminders.Lists: @unchecked Sendable {}
extension Reminders.Tags: @unchecked Sendable {}
