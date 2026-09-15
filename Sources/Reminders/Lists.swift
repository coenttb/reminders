public import Foundation
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

        public func list(_ id: Reminder.List.ID) -> Reminder.List? { lists.first { $0.id == id }?.list }
    }
}

extension Lists {
    /// The calendar day a moment falls in, as half-open bounds, so "today" is decided by the
    /// calendar the app is given rather than by the database's own idea of local time.
    public static func day(containing now: Date, calendar: Calendar) -> Range<Date> {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return start..<end
    }
}
