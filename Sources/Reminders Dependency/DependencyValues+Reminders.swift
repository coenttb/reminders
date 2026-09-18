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
            create: .init(run: unimplemented("\\.reminders.create")),
            read: .init(
                run: unimplemented("\\.reminders.read", placeholder: AsyncThrowingStream { $0.finish() }),
                id: unimplemented("\\.reminders.read(id)"),
                page: unimplemented("\\.reminders.read(page:)", placeholder: AsyncThrowingStream { $0.finish() })
            ),
            update: .init(
                run: unimplemented("\\.reminders.update"),
                complete: unimplemented("\\.reminders.update.complete")
            ),
            delete: .init(run: unimplemented("\\.reminders.delete")),
            lists: .init(
                create: unimplemented("\\.reminders.lists.create"),
                delete: unimplemented("\\.reminders.lists.delete")
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
