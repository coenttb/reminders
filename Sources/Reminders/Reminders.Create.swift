public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Create: Create.Interface {
        @Operations
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) async throws
        }
    }
}
