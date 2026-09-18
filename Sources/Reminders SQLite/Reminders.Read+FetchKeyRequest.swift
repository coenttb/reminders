public import Models
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
import Tagged

// The read requests are the fetch keys: a feature observes a domain address and SQLite resolves it.
extension Reminders.Read.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Summary {
        Reminders.Summary(
            lists: try Models.List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { Models.List<Reminder>.Record.Entry.Columns(list: $0, count: $1.id.count(filter: $1.completed.eq(false))) }
                .fetchAll(db)
                .map(Models.List<Reminder>.Entry.init)
        )
    }
}

extension Reminders.Read.Page.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Page {
        Reminders.Page(
            rows: try Reminder.Record
                .where { $0.belongs(to: filter) }
                .order(by: \.position)
                .fetchAll(db)
                .map(Reminder.init)
        )
    }
}
