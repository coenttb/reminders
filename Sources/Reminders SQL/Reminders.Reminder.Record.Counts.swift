public import Reminders
public import StructuredQueries

extension Reminders.Reminder.Record {
    @Selection
    public struct Counts: Hashable, Sendable {
        public var all: Int
        public var flagged: Int
        public var scheduled: Int
        public var today: Int

        public init(all: Int = 0, flagged: Int = 0, scheduled: Int = 0, today: Int = 0) {
            self.all = all
            self.flagged = flagged
            self.scheduled = scheduled
            self.today = today
        }
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
