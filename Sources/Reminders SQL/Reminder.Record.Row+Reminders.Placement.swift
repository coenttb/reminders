public import Reminder
public import Reminders

extension Reminders.Placement {
    public init(_ row: Reminder.Record.Row) {
        self.init(Reminder(row), position: row.reminder.position)
    }
}
