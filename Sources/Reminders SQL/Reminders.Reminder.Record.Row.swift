public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    /// A reminder with the titles of its tags, the shape a screen reads.
    @Selection
    public struct Row: Hashable, Sendable {
        public let reminder: Reminder.Record
        @Column(as: [String].JSONRepresentation.self)
        public let tags: [String]

        public init(reminder: Reminder.Record, tags: [String]) {
            self.reminder = reminder
            self.tags = tags
        }
    }
}
