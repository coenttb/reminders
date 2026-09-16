public import Reminders
public import Reminders_Application
public import SQLiteData

extension Reminder.Completion.Pending.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminder.Completion.Pending {
        Reminder.Completion.Pending(Set(try Reminder.Record.where { $0.isPending }.select(\.id).fetchAll(db)))
    }
}
