public import Reminders
public import Reminders_SQLite
public import SQLiteData

extension Reminders.Feature {
    // A listing is fetched only while there is a selection; `nil` clears the page.
    public struct Fetching: FetchKeyRequest, Hashable, Sendable {
        public var request: Reminders.Page.Query?

        public init(_ request: Reminders.Page.Query?) {
            self.request = request
        }

        public func fetch(_ db: Database) throws -> Reminders.Page? {
            try request?.fetch(db)
        }
    }
}
