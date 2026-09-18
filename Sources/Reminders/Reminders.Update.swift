public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Update: Update.Interface {
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) async throws
            // Completion is its own write, so no feature reads a row to toggle it.
            func complete(_ id: Reminder.ID, _ completed: Bool) async throws
        }
    }
}
