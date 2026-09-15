public import Foundation
import Standard_Library_Extensions
public import Tagged

/// The Reminders domain: the screens the app shows (the home, a detail, the search) and
/// the rules every platform shares. The records themselves live in the database; what a
/// screen shows is read from it as one of the read models below, never held as a second
/// copy of the data.
public enum Lists {}

extension Lists {
    /// The home screen as read from the database: the user's lists in their order with
    /// their open counts, the smart-group counts, the tags at least one reminder carries,
    /// and every tag ranked by use for the picker.
    public struct Home: Hashable, Sendable {
        public var lists: [Entry]
        public var stats: Stats
        public var usedTags: [Tag]
        public var rankedTags: [Tag]

        public init(lists: [Entry] = [], stats: Stats = Stats(), usedTags: [Tag] = [], rankedTags: [Tag] = []) {
            self.lists = lists
            self.stats = stats
            self.usedTags = usedTags
            self.rankedTags = rankedTags
        }

        /// One list on the home screen with the number of reminders still open in it.
        public struct Entry: Identifiable, Hashable, Sendable {
            public var list: Reminder.List
            public var count: Int

            public var id: Reminder.List.ID { list.id }

            public init(list: Reminder.List, count: Int) {
                self.list = list
                self.count = count
            }
        }

        public func list(_ id: Reminder.List.ID) -> Reminder.List? { lists.first(id: id)?.list }
    }
}
