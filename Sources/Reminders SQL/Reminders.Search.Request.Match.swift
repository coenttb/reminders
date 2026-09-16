public import Organizing
public import Reminders
public import Reminders_Interface
public import StructuredQueries

extension Reminders.Search.Request {
    @Selection
    public struct Match {
        public let reminder: Reminder.Record
        public let tags: String?
        public let list: List<Reminder>.Record
    }
}
