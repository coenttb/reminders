public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Update: Update.Interface {
        @Operations
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) async throws
            var complete: Reminders.Update.Complete { get }
        }
    }
}
