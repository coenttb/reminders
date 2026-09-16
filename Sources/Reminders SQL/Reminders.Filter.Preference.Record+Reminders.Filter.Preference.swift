public import Reminders
public import Reminders_Interface

extension Reminders.Filter.Preference {
    public init(_ record: Reminders.Filter.Preference.Record) {
        self.init(ordering: Reminders.Ordering(rawValue: record.ordering) ?? .dueDate, showCompleted: record.showCompleted)
    }
}
