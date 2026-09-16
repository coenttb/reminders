public import Organizing
public import Reminders
public import SQLiteData

extension Reminder.Record {
    @Selection
    public struct Row: Sendable {
        public let reminder: Reminder.Record
        public let tags: String?
        public let color: Color.Hex
    }
}
