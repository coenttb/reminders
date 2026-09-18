public import Reminder

extension Reminders {
    public struct Page: Hashable, Sendable {
        public var rows: [Reminder]

        public init(rows: [Reminder] = []) {
            self.rows = rows
        }
    }
}
