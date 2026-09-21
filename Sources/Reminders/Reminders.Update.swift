public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Update: Update.Interface, Sendable {
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder) async throws
            var complete: Reminders.Update.Complete { get }
        }
    }
}
