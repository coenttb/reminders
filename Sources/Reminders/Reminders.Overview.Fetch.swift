public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders.Overview {
    public struct Fetch: Sendable {
        public typealias Client = Models.Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
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
        public var lists: [Models.List<Reminder>.Entry]
        public var counts: Reminders.Overview.Counts
        public var tags: [Tag<Reminder>.Entry]

        public init(lists: [Models.List<Reminder>.Entry] = [], counts: Reminders.Overview.Counts = Reminders.Overview.Counts(), tags: [Tag<Reminder>.Entry] = []) {
            self.lists = lists
            self.counts = counts
            self.tags = tags
        }
    }
}
