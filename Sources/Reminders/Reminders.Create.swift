public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Create: Create.Interface, Sendable {
        public protocol Interface {
            // Storage gives the draft its identity and creation time; the created reminder comes back.
            func callAsFunction(_ draft: Reminder.Draft) async throws -> Reminder
        }
    }
}
