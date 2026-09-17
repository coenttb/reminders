public import Reminders
import Reminders_SQLite
public import SQLiteData

extension Reminders.Feature {
    // A listing is fetched only while there is a selection; `nil` clears the page.
    public struct Fetching: FetchKeyRequest, Hashable, Sendable {
        public var request: Reminders.List.Request?

        public init(_ request: Reminders.List.Request?) {
            self.request = request
        }

        public func fetch(_ db: Database) throws -> Reminders.List.Result? {
            try request?.fetch(db)
        }
    }
}
