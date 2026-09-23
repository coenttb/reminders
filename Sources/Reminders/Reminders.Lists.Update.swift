public import Interface_Macro
public import List
public import Reminder

extension Reminders.Lists {
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Update: Update.Interface, Sendable {
        public protocol Interface {
            func callAsFunction(_ list: List<Reminder>) async throws
        }
    }
}
