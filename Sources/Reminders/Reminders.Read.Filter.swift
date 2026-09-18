public import List
public import Reminder

extension Reminders.Read {
    public enum Filter: Hashable, Sendable {
        case all
        case list(List<Reminder>.ID)
    }
}
