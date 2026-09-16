public import Reminders

extension Reminders.Reminder.Record: Reminders.Reminder.Fields {
    public var completed: Bool { status != .incomplete }
}
