public import Foundation
public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Update: Update.Interface {
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) async throws -> Reminders.Placement
            func recover(_ id: Reminder.ID) async throws
            func order(_ filter: Reminders.Filter, by ordering: Reminders.Ordering) async throws
            func turn(_ filter: Reminders.Filter, _ direction: SortOrder) async throws
            func show(completed: Bool, in filter: Reminders.Filter) async throws
            func reorder(_ ids: [Reminder.ID], in filter: Reminders.Filter) async throws
        }
    }
}
