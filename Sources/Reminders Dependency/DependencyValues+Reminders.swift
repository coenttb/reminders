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
                id: unimplemented("\\.reminders.read(id)"),
                page: unimplemented("\\.reminders.read(page:)", placeholder: Page())
            ),
            observe: .init(
                summary: unimplemented("\\.reminders.observe(summary)", placeholder: AsyncThrowingStream { $0.finish() }),
                page: unimplemented("\\.reminders.observe(page)", placeholder: AsyncThrowingStream { $0.finish() })
            ),
            update: .init(unimplemented("\\.reminders.update")),
            delete: .init(unimplemented("\\.reminders.delete")),
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
extension Reminders.Observe: @unchecked Sendable {}
extension Reminders.Update: @unchecked Sendable {}
extension Reminders.Delete: @unchecked Sendable {}
extension Reminders.Lists: @unchecked Sendable {}
