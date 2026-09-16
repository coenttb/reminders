public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SQLiteData

extension Reminders.Pending.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Pending {
        Reminders.Pending(Set(try Reminder.Record.where { $0.isPending }.select(\.id).fetchAll(db)))
    }
}
