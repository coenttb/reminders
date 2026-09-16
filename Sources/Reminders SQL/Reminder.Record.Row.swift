public import Reminder
public import StructuredQueries

extension Reminder.Record {
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
