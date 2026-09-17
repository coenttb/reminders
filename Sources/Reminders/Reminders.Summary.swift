public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders {
    public struct Summary: Hashable, Sendable {
        public var lists: [Models.List<Reminder>.Entry]
        public var counts: Reminders.Summary.Counts
        public var tags: [Tag<Reminder>.Entry]

        public init(lists: [Models.List<Reminder>.Entry] = [], counts: Reminders.Summary.Counts = Reminders.Summary.Counts(), tags: [Tag<Reminder>.Entry] = []) {
            self.lists = lists
            self.counts = counts
            self.tags = tags
        }
    }
}
