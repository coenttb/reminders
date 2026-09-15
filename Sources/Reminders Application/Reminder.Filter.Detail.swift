public import Organizing
public import Reminders
public import Tagged

extension Reminder.Filter {
    /// One filter as read from the database: its list's color when it is a list, its
    /// preference, and the reminders it shows in the preference's order, each with the
    /// color of the list it belongs to.
    public struct Detail: Hashable, Sendable {
        public var filter: Reminder.Filter
        public var color: Color?
        public var preference: Preference
        public var rows: [Row]

        public init(filter: Reminder.Filter, color: Color? = nil, preference: Preference, rows: [Row] = []) {
            self.filter = filter
            self.color = color
            self.preference = preference
            self.rows = rows
        }

        /// One reminder in a detail, tinted by its list.
        public struct Row: Identifiable, Hashable, Sendable {
            public var reminder: Reminder
            public var color: Color

            public var id: Reminder.ID { reminder.id }

            public init(reminder: Reminder, color: Color) {
                self.reminder = reminder
                self.color = color
            }
        }

        public var reminders: [Reminder] { rows.map(\.reminder) }
    }
}
