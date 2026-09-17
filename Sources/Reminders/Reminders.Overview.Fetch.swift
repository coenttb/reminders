public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders.Overview {
    public enum Fetch {
        public typealias Client = Models.Operation<Request, Result>
    }
}

extension Reminders.Overview.Fetch {
    public struct Request: Hashable, Sendable {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }
    }
}

extension Reminders.Overview.Fetch {
    public struct Result: Hashable, Sendable {
        public var lists: [List<Reminder>.Entry]
        public var counts: Reminders.Overview.Counts
        public var tags: [Tag<Reminder>.Entry]

        public init(lists: [List<Reminder>.Entry] = [], counts: Reminders.Overview.Counts = Reminders.Overview.Counts(), tags: [Tag<Reminder>.Entry] = []) {
            self.lists = lists
            self.counts = counts
            self.tags = tags
        }
    }
}
