public import Foundation

extension Lists {
    /// The counts on the home grid.
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

    public func stats(at now: Date, calendar: Calendar = .current) -> Stats {
        let open = reminders.filter { !$0.completed }
        return Stats(
            all: open.count,
            flagged: open.filter(\.flagged).count,
            scheduled: open.filter(\.scheduled).count,
            today: open.filter { $0.dueToday(at: now, calendar: calendar) }.count
        )
    }
}
