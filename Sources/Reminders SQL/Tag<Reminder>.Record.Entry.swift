public import Organizing
public import Reminders
public import StructuredQueries

extension Tag<Reminder>.Record {
    /// A tag with the number of reminders carrying it.
    @Selection
    public struct Entry: Hashable, Sendable {
        public let tag: Tag<Reminder>.Record
        public let count: Int
    }
}
