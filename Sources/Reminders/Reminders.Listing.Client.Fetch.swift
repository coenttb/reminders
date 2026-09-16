public import Foundation
public import Models
public import Reminder

extension Reminders.Listing.Client {
    public struct Fetch: Models.Operation {
        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Listing.Client.Fetch {
    public struct Request: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var today: Range<Date>
        public var place: Reminders.Placement?
        public var limit: Int?

        public init(selection: Reminders.Selection, today: Range<Date>, place: Reminders.Placement? = nil, limit: Int? = nil) {
            self.selection = selection
            self.today = today
            self.place = place
            self.limit = limit
        }
    }
}

extension Reminders.Listing.Client.Fetch {
    public struct Result: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var preference: Reminders.Preference
        public var rows: [Reminder]
        public var total: Int
        public var completed: Int

        public init(
            selection: Reminders.Selection,
            preference: Reminders.Preference,
            rows: [Reminder] = [],
            total: Int = 0,
            completed: Int = 0
        ) {
            self.selection = selection
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completed = completed
        }
    }
}
