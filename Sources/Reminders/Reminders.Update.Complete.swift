public import Interface_Macro
public import Reminder

extension Reminders.Update {
    // Completion is its own write, so no feature reads a row to toggle it.
    @Interface
    public struct Complete: Complete.Interface {
        @Operations
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID, _ completed: Bool) async throws
        }
    }
}
