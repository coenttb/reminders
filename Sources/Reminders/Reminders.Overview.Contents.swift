public import Models
public import Reminder
public import Tagged

extension Reminders.Overview {
    public struct Contents: Hashable, Sendable {
        public var lists: [List<Reminder>.Entry]
        public var counts: Counts
        public var tags: [Tag<Reminder>.Entry]

        public init(lists: [List<Reminder>.Entry] = [], counts: Counts = Counts(), tags: [Tag<Reminder>.Entry] = []) {
            self.lists = lists
            self.counts = counts
            self.tags = tags
        }
    }
}
