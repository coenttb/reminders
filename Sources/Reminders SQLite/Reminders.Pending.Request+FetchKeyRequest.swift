public import Reminders
public import Reminders_Interface
import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Pending.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Set<Reminder.ID> {
        Set(try Reminder.Record.where { $0.isPending }.select(\.id).fetchAll(db))
    }
}
