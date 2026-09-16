public import Reminder
public import Reminders

extension Reminders.Session {
    public struct Client: Sendable {
        public var current: @Sendable () throws -> Reminders.Session
        public var setFilter: @Sendable (Reminders.Filter?) throws -> Void
        public var setEditing: @Sendable (Reminder.ID?) throws -> Void

        public init(
            current: @escaping @Sendable () throws -> Reminders.Session,
            setFilter: @escaping @Sendable (Reminders.Filter?) throws -> Void,
            setEditing: @escaping @Sendable (Reminder.ID?) throws -> Void
        ) {
            self.current = current
            self.setFilter = setFilter
            self.setEditing = setEditing
        }
    }
}
