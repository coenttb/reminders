public import Organizing
public import Reminders
public import Reminders_Interface
public import StructuredQueries

extension Reminders.Overview.Request {
    @Selection
    public struct Entry {
        public let list: List<Reminder>.Record
        public let count: Int
    }
}
