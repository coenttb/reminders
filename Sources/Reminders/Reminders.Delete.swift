public import Foundation
public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Delete: Delete.Interface {
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID) throws
            func completed(in filter: Reminders.Filter, today: Date) throws
            func completed(matching query: Reminders.Query, dueBefore: Date?) throws
        }
    }
}

