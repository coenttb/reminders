public import Reminders
import Reminders_SQLite
public import SQLiteData

extension Reminders.Feature {
    // A listing is fetched only while there is a selection; `nil` clears the page.
    public struct Fetching: FetchKeyRequest, Hashable, Sendable {
        public var request: Reminders.Listing.Fetch.Request?

        public init(_ request: Reminders.Listing.Fetch.Request?) {
            self.request = request
        }

        public func fetch(_ db: Database) throws -> Reminders.Listing.Fetch.Result? {
            try request?.fetch(db)
        }
    }
}
