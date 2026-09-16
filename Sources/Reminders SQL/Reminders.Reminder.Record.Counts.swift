public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    /// How many open reminders each smart filter holds.
    @Selection
    public struct Counts: Hashable, Sendable {
        public var all = 0
        public var flagged = 0
        public var scheduled = 0
        public var today = 0
    }
}

extension Reminders.Reminder.Record.Counts {
    public subscript(_ filter: Reminders.Filter) -> Int? {
        switch filter {
        case .all: all
        case .flagged: flagged
        case .scheduled: scheduled
        case .today: today
        case .completed, .list, .tags: nil
        }
    }
}
