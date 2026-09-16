public import Organizing
public import Reminders
public import StructuredQueries

extension Tag<Reminder>.Record {
    @Selection
    public struct Entry: Hashable, Sendable {
        public let tag: Tag<Reminder>.Record
        public let count: Int

        public init(tag: Tag<Reminder>.Record, count: Int) {
            self.tag = tag
            self.count = count
        }
    }
}
