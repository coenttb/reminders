extension Lists {
    /// The counts on the home grid: open reminders only.
    public struct Stats: Hashable, Sendable {
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
