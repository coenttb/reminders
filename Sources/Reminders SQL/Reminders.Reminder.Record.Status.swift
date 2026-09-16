public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    /// What the `status` column holds: `pending` is the grace period between the tap and completed.
    public enum Status: Int, QueryBindable {
        case incomplete = 0
        case completed = 1
        case pending = 2
    }
}
