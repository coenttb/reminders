public import Organizing
public import Reminders
public import StructuredQueries

extension Select<(), Reminders.Reminder.Record, ()> {
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, List<Reminder>.Record> {
        join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
            .select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tagList, color: $1.color) }
    }
}
