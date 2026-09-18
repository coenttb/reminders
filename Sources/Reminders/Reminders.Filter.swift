public import Models
public import Reminder

extension Reminders {
    public enum Filter: Hashable, Sendable {
        case all
        case list(Models.List<Reminder>.ID)
    }
}
