public import Models
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders.Tags {
    public struct Query: FetchKeyRequest {
        public var prefix: String
        public var excluding: Set<Tag<Reminder>>

        public init(prefix: String, excluding: Set<Tag<Reminder>> = []) {
            self.prefix = prefix
            self.excluding = excluding
        }

        public init(_ request: Reminders.Tags.List.Request) {
            self.init(prefix: request.prefix, excluding: request.excluding)
        }
    }
}

extension Reminders.Tags.Query {
    public func fetch(_ db: Database) throws -> [Tag<Reminder>] {
        guard !prefix.isEmpty else { return [] }
        let taken = excluding.map(\.rawValue)
        return try Tag<Reminder>.Record
            .where { Reminders.Schema.$hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
            .order { $0.title.collate(Reminders.Schema.$localizedCaseInsensitive) }
            .fetchAll(db)
            .map(Tag<Reminder>.init)
    }
}
