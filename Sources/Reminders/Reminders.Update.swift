public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Update: Update.Interface {
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) throws -> Reminders.Placement
            func order(_ filter: Reminders.Filter, by ordering: Reminders.Ordering) throws
            func show(completed: Bool, in filter: Reminders.Filter) throws
            func reorder(_ ids: [Reminder.ID], in filter: Reminders.Filter) throws
        }
    }
}
