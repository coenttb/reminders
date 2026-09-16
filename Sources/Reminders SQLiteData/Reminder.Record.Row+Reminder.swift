public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder {
    public init(_ row: Reminder.Record.Row) {
        self.init(row.reminder, tags: Reminder.Record.tags(from: row.tags))
    }
}
