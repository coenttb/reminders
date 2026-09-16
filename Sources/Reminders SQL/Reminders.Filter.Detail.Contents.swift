public import Reminders
public import Reminders_Interface
public import Tagged

extension Reminders.Filter.Detail {
    /// What one filter's screen reads: its rows in the preferred order, and how many there are in all.
    public struct Contents: Hashable, Sendable {
        public var filter: Reminders.Filter
        public var preference: Reminders.Filter.Preference
        public var rows: [Reminder.Record.Row]
        public var total: Int
        public var completedCount: Int

        public init(
            filter: Reminders.Filter,
            preference: Reminders.Filter.Preference,
            rows: [Reminder.Record.Row] = [],
            total: Int = 0,
            completedCount: Int = 0
        ) {
            self.filter = filter
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completedCount = completedCount
        }
    }
}

extension Reminders.Filter.Detail.Contents {
    public var ids: [Reminder.ID] { rows.map(\.reminder.id) }
}
