public import Organizing
public import Reminders
public import StructuredQueries

extension List<Reminder>.Record {
    /// A list on the overview with the number of its open reminders.
    @Selection
    public struct Entry: Hashable, Sendable {
        public let list: List<Reminder>.Record
        public let count: Int
    }
}
