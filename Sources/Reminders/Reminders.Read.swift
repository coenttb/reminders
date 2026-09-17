public import Foundation
public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Read: Read.Interface {
        public protocol Interface {
            func callAsFunction() throws -> Reminders.Summary
            func callAsFunction(today: Date) throws -> Reminders.Summary
            func callAsFunction(_ id: Reminder.ID) throws -> Reminders.Placement
            func callAsFunction(page filter: Reminders.Filter, today: Date, including: Reminders.Placement?, limit: Int?) throws -> Reminders.Page
            func callAsFunction(search query: Reminders.Query, today: Date, limit: Int?) throws -> Reminders.Page
            func preference(for filter: Reminders.Filter) throws -> Reminders.Preference
        }
    }
}
