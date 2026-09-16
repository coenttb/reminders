import Organizing
public import Reminders
import SQLiteData
import Tagged

extension Reminder {
    public init(_ row: Reminder.Record.Row) {
        self.init(row.reminder, tags: Reminder.Record.tags(from: row.tags))
    }
}
