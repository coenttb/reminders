public import Reminders
public import Reminders_Interface

extension Reminders.Session {
    public init(_ record: Reminders.Session.Record) {
        self.init(filter: record.filter.flatMap(Reminders.Filter.init(key:)), editing: record.editing)
    }
}
