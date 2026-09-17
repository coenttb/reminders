public import Reminder

extension Reminders {
    public struct Page: Hashable, Sendable {
        public var rows: [Reminder]
        public var total: Int
        public var completed: Int

        public init(rows: [Reminder] = [], total: Int = 0, completed: Int = 0) {
            self.rows = rows
            self.total = total
            self.completed = completed
        }
    }
}
