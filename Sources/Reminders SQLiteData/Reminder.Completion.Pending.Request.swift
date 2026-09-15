public import Reminders
public import Reminders_Application
public import SQLiteData

extension Reminder.Completion.Pending {
    /// Reads which reminders are in their grace period, and again whenever that changes, so the
    /// grace timer follows the table however a reminder came to be pending.
    public struct Request: FetchKeyRequest {
        public init() {}

        public func fetch(_ db: Database) throws -> Reminder.Completion.Pending {
            Reminder.Completion.Pending(Set(try Reminder.Record.where { $0.isPending }.select(\.id).fetchAll(db)))
        }
    }
}
