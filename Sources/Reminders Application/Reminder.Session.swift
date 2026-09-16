public import Reminders

extension Reminder {
    public struct Session: Hashable, Sendable {
        public var filter: Filter?
        public var editing: Reminder.ID?

        public init(filter: Filter? = nil, editing: Reminder.ID? = nil) {
            self.filter = filter
            self.editing = editing
        }
    }
}
