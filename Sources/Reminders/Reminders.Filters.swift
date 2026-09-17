public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Filters: Filters.Interface {
        public protocol Interface {
            func page(of filter: Reminders.Filter, today: Reminders.Day, including: Reminders.Placement?, limit: Int?) throws -> Reminders.Page
            func preference(for filter: Reminders.Filter) throws -> Reminders.Preference
            func order(_ filter: Reminders.Filter, by ordering: Reminders.Ordering) throws
            func show(completed: Bool, in filter: Reminders.Filter) throws
            func reorder(_ ids: [Reminder.ID], in filter: Reminders.Filter) throws
        }
    }
}

