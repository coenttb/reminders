public import Reminders

extension Reminders.Reminder.Record.Draft: Reminders.Reminder.Fields {
    public var completed: Bool { status != .incomplete }
}
