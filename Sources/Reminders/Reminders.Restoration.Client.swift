public import Reminder
public import Tagged

extension Reminders.Restoration {
    public struct Client: Sendable {
        public var current: @Sendable () throws -> Reminders.Session
        public var setFilter: @Sendable (Reminders.Filter?) async throws -> Void
        public var setEditing: @Sendable (Reminder.ID?) async throws -> Void

        public init(
            current: @escaping @Sendable () throws -> Reminders.Session,
            setFilter: @escaping @Sendable (Reminders.Filter?) async throws -> Void,
            setEditing: @escaping @Sendable (Reminder.ID?) async throws -> Void
        ) {
            self.current = current
            self.setFilter = setFilter
            self.setEditing = setEditing
        }
    }
}
