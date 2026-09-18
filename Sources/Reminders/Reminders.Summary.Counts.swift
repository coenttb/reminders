extension Reminders.Summary {
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
