public import Reminder
public import Reminders
public import StructuredQueries

extension Reminder.Record {
    @Selection
    public struct Counts: Hashable, Sendable {
        public var all: Int
        public var flagged: Int
        public var scheduled: Int
        public var today: Int
        public var deleted: Int

        public init(all: Int = 0, flagged: Int = 0, scheduled: Int = 0, today: Int = 0, deleted: Int = 0) {
            self.all = all
            self.flagged = flagged
            self.scheduled = scheduled
            self.today = today
            self.deleted = deleted
        }
    }
}

extension Reminders.Summary.Counts {
    public init(_ counts: Reminder.Record.Counts) {
        self.init(all: counts.all, flagged: counts.flagged, scheduled: counts.scheduled, today: counts.today, deleted: counts.deleted)
    }
}
