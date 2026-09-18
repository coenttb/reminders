public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Create: Create.Interface {
        @Operations
        public protocol Interface {
            // Storage gives the draft its identity and creation time; the created reminder comes back.
            func callAsFunction(_ draft: Reminder.Draft) async throws -> Reminder
        }
    }
}
