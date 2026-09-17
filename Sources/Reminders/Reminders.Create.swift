public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Create: Create.Interface {
        public protocol Interface {
            func callAsFunction(_ reminder: Reminder, below: Reminders.Placement?) throws -> Reminders.Placement
        }
    }
}
