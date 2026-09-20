public import Interface_Macro
public import List
public import Reminder

extension Reminders.Read {
    @Prisms
    @dynamicMemberLookup
    public enum Filter: Hashable, Sendable {
        case all
        case list(List<Reminder>.ID)
    }
}
