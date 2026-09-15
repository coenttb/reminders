public import Reminders

extension Reminder {
    /// Where the user is: the open filter and the row being edited in place, kept across launches.
    public struct Navigation: Hashable, Sendable {
        public var filter: Filter?
        public var editing: Reminder.ID?

        public init(filter: Filter? = nil, editing: Reminder.ID? = nil) {
            self.filter = filter
            self.editing = editing
        }
    }
}
