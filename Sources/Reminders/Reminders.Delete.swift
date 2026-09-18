public import Foundation
public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Delete: Delete.Interface {
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID) async throws
            func permanently(_ id: Reminder.ID) async throws
            func expired(before cutoff: Date) async throws
            func blank() async throws
            func completed(in filter: Reminders.Filter, today: Date) async throws
            func completed(matching query: Reminders.Query, dueBefore: Date?) async throws
        }
    }
}

