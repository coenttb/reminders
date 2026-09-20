public import Interface_Macro
public import List
public import Reminder

extension Reminders.Read {
    @Memberwise
    public struct Value: Hashable, Sendable {
        public var lists: [List<Reminder>.Entry] = []
    }
}
