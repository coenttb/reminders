public import Reminder
public import Tagged

extension Reminders {
    public struct Page: Hashable, Sendable {
        public var rows: [Reminder]
        public var total: Int
        public var completed: Int
        public var highlights: [Reminder.ID: Reminders.Highlight]

        public init(rows: [Reminder] = [], total: Int = 0, completed: Int = 0, highlights: [Reminder.ID: Reminders.Highlight] = [:]) {
            self.rows = rows
            self.total = total
            self.completed = completed
            self.highlights = highlights
        }
    }
}
