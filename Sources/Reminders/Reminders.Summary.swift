public import Models
public import Reminder

extension Reminders {
    public struct Summary: Hashable, Sendable {
        public var lists: [Models.List<Reminder>.Entry]
        // The lists deleted in the last thirty days, so Recently Deleted can still name them.
        public var trash: [Models.List<Reminder>]
        public var counts: Reminders.Summary.Counts
        public var tags: [Tag<Reminder>.Entry]

        public init(lists: [Models.List<Reminder>.Entry] = [], trash: [Models.List<Reminder>] = [], counts: Reminders.Summary.Counts = Reminders.Summary.Counts(), tags: [Tag<Reminder>.Entry] = []) {
            self.lists = lists
            self.trash = trash
            self.counts = counts
            self.tags = tags
        }
    }
}
