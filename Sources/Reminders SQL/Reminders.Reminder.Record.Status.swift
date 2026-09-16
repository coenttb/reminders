public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    public enum Status: Int, Hashable, Sendable, QueryBindable {
        case incomplete = 0
        case completed = 1
        case pending = 2
    }
}
