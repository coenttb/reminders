import Foundation
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

extension Reminders.Overview.Contents {
    public var usedTags: [Tag<Reminder>] {
        tags.filter { $0.count > 0 }.map(\.tag).sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
    }

    public var rankedTags: [Tag<Reminder>] { tags.map(\.tag) }

    public func list(_ id: List<Reminder>.ID) -> List<Reminder>? { lists.first { $0.id == id }?.list }
}
