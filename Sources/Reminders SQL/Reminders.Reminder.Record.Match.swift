public import Organizing
public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    /// A search hit: the reminder, its tags, and the list it sits in.
    @Selection
    public struct Match: Hashable, Sendable {
        public let reminder: Reminder.Record
        @Column(as: [String].JSONRepresentation.self)
        public let tags: [String]
        public let list: List<Reminder>.Record

        public init(reminder: Reminder.Record, tags: [String], list: List<Reminder>.Record) {
            self.reminder = reminder
            self.tags = tags
            self.list = list
        }
    }
}
