public import Reminder

extension Reminders.Read.Page {
    public struct Value: Hashable, Sendable {
        public var rows: [Reminder]

        public init(rows: [Reminder] = []) {
            self.rows = rows
        }
    }
}
