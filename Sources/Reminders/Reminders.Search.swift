public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Search: Search.Interface {
        public protocol Interface {
            func page(matching query: Reminders.Search.Query, today: Reminders.Day, limit: Int?) throws -> Reminders.Page
        }
    }
}

