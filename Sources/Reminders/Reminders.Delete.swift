public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Delete: Delete.Interface {
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID) async throws
        }
    }
}
