public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Delete: Delete.Interface, Sendable {
        public protocol Interface {
            func callAsFunction(_ id: Reminder.ID) async throws
        }
    }
}
