public import Interface_Macro
public import Reminder

extension Reminders {
    // Reads are synchronous: a feature observes a read's request as a fetch key and storage resolves it.
    @Interface
    public struct Read: Read.Interface {
        public protocol Interface {
            func callAsFunction() throws -> Reminders.Summary
            func callAsFunction(_ id: Reminder.ID) throws -> Reminder
            func callAsFunction(page filter: Reminders.Filter) throws -> Reminders.Page
        }
    }
}
