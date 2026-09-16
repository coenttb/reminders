import Foundation
public import Organizing
public import Reminders
public import Reminders_Interface
public import Tagged

extension Reminders.Overview {
    /// What the home screen reads: the lists with their open counts, the smart filter counts, and
    /// the tags ranked by use.
    public struct Contents: Hashable, Sendable {
        public var lists: [List<Reminder>.Record.Entry]
        public var counts: Reminder.Record.Counts
        public var tags: [Tag<Reminder>.Record.Entry]

        public init(
            lists: [List<Reminder>.Record.Entry] = [],
            counts: Reminder.Record.Counts = Reminder.Record.Counts(),
            tags: [Tag<Reminder>.Record.Entry] = []
        ) {
            self.lists = lists
            self.counts = counts
            self.tags = tags
        }
    }
}

extension Reminders.Overview.Contents {
    /// The tags on at least one reminder, by title.
    public var usedTags: [Tag<Reminder>.Record] {
        tags.filter { $0.count > 0 }.map(\.tag).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Every tag, the most used first.
    public var rankedTags: [Tag<Reminder>.Record] { tags.map(\.tag) }

    public func list(_ id: List<Reminder>.ID) -> List<Reminder>.Record? { lists.first { $0.list.id == id }?.list }
}
