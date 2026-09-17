public import Foundation
public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Delete: Delete.Interface {
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID) throws
            func completed(in filter: Reminders.Filter, today: Reminders.Day) throws
            func completed(matching query: Reminders.Search.Query, dueBefore: Date?) throws
        }
    }
}

