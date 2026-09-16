public import Reminder

extension Reminders.Listing {
    public struct Page: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var preference: Reminders.Preference
        public var rows: [Reminder]
        public var total: Int
        public var completed: Int

        public init(
            selection: Reminders.Selection,
            preference: Reminders.Preference,
            rows: [Reminder] = [],
            total: Int = 0,
            completed: Int = 0
        ) {
            self.selection = selection
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completed = completed
        }
    }
}
