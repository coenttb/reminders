public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders.Overview.Client {
    public struct Fetch: Models.Operation {
        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Overview.Client.Fetch {
    public struct Request: Hashable, Sendable {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }
    }
}

extension Reminders.Overview.Client.Fetch {
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
