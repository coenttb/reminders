public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders.Preference {
    public struct Query: FetchKeyRequest {
        public var filter: Reminders.Filter

        public init(for filter: Reminders.Filter) {
            self.filter = filter
        }

        public init(_ request: Reminders.Read.Preference.Request) {
            self.init(for: request.filter)
        }
    }
}

extension Reminders.Preference.Query {
    public func fetch(_ db: Database) throws -> Reminders.Preference {
        try Reminders.Preference.Record.preference(for: filter).fetchOne(db).map(Reminders.Preference.init)
            ?? Reminders.Preference(Reminders.Preference.Record.default(for: filter))
    }
}
