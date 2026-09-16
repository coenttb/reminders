public import Reminders
public import Reminders_Application

extension Reminder.Filter.Preference {
    public init(_ record: Reminder.Filter.Preference.Record) {
        self.init(ordering: Reminder.Ordering(rawValue: record.ordering) ?? .dueDate, showCompleted: record.showCompleted)
    }
}
