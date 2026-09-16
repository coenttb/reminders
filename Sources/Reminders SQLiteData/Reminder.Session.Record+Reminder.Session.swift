public import Reminders
public import Reminders_Application

extension Reminder.Session {
    public init(_ record: Reminder.Session.Record) {
        self.init(filter: record.filter.flatMap(Reminder.Filter.init(key:)), editing: record.editing)
    }
}
