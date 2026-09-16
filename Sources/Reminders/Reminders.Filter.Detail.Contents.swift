public import Reminder
public import Tagged

extension Reminders.Filter.Detail {
    public struct Contents: Hashable, Sendable {
        public var filter: Reminders.Filter
        public var preference: Reminders.Filter.Preference
        public var rows: [Reminder]
        public var total: Int
        public var completedCount: Int

        public init(
            filter: Reminders.Filter,
            preference: Reminders.Filter.Preference,
            rows: [Reminder] = [],
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
    public var ids: [Reminder.ID] { rows.map(\.id) }
}
