public import Reminders
public import Reminders_Application
import SQLiteData

extension Reminder.Completion.Pending {
    public struct Request: Hashable, Sendable {
        public init() {}
    }
}
