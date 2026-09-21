public import Interface_Macro
public import List
public import Reminder

extension Reminders.Lists {
    // Storage gives the draft its identity; the created list comes back.
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Create: Create.Interface, Sendable {
        public protocol Interface {
            func callAsFunction(_ draft: List<Reminder>.Draft) async throws -> List<Reminder>
        }
    }
}
