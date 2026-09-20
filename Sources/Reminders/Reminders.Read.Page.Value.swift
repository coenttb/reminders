public import Interface_Macro
public import Reminder

extension Reminders.Read.Page {
    @Memberwise
    public struct Value: Hashable, Sendable {
        public var rows: [Reminder] = []
    }
}
