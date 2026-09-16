public import Organizing
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminders {
    public struct Overview: Hashable, Sendable {
        public var lists: [List<Reminder>.Entry]
        public var counts: Filter.Counts
        public var usedTags: [Tag<Reminder>]
        public var rankedTags: [Tag<Reminder>]

        public init(
            lists: [List<Reminder>.Entry] = [],
            counts: Filter.Counts = Filter.Counts(),
            usedTags: [Tag<Reminder>] = [],
            rankedTags: [Tag<Reminder>] = []
        ) {
            self.lists = lists
            self.counts = counts
            self.usedTags = usedTags
            self.rankedTags = rankedTags
        }

        public func list(_ id: List<Reminder>.ID) -> List<Reminder>? { lists.first(id: id)?.list }
    }
}
