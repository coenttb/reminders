public import Interface_Macro
public import List
public import Reminder

extension Reminders.Lists {
    // Storage gives the draft its identity; the created list comes back.
    @Interface(.sendable)
    public struct Create: Create.Interface {
        public protocol Interface {
            func callAsFunction(_ draft: List<Reminder>.Draft) async throws -> List<Reminder>
        }
    }
}
