public import Organizing
public import Reminders
public import Tagged

extension Reminder.Filter {
    /// One filter as read from the database: its list's color when it is a list, its
    /// preference, the first rows it shows in the preference's order, each with the color of
    /// the list it belongs to, how many rows it has in all, and how many of those are completed.
    public struct Detail: Hashable, Sendable {
        public var filter: Reminder.Filter
        public var color: Color?
        public var preference: Preference
        public var rows: [Row] { didSet { ids = rows.map(\.id) } }
        public var total: Int
        public var completedCount: Int
        /// The rows' identifiers, kept so a screen compares them without walking the rows.
        public private(set) var ids: [Reminder.ID]

        public init(filter: Reminder.Filter, color: Color? = nil, preference: Preference, rows: [Row] = [], total: Int = 0, completedCount: Int = 0) {
            self.filter = filter
            self.color = color
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completedCount = completedCount
            self.ids = rows.map(\.id)
        }

        /// Whether the query has rows beyond the ones read.
        public var hasMore: Bool { rows.count < total }

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
