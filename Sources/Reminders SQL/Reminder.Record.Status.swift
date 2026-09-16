public import Reminder
public import StructuredQueries

extension Reminder.Record {
    public enum Status: Int, Hashable, Sendable, QueryBindable {
        case incomplete = 0
        case completed = 1
        case pending = 2
    }
}
