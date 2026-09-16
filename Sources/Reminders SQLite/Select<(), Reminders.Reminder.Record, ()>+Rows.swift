public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Select<(), Reminders.Reminder.Record, ()> {
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, ()> {
        select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tags) }
    }
}
