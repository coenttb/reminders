import Organizing
public import Reminders
import StructuredQueries
import Tagged

extension Reminders.Reminder {
    public init(_ row: Reminder.Record.Row) {
        self.init(row.reminder, tags: Reminder.Record.tags(from: row.tags))
    }
}
