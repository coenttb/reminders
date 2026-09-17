public import Reminder
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record {
    // The full-text index of a reminder: its title, its notes, and its tag titles, kept in step by
    // triggers and addressed by the reminder's rowid.
    @Table("reminderTexts")
    public struct Text: FTS5, Sendable {
        public let rowid: Int
        public var title: String
        public var notes: String
        public var tags: String
    }
}
