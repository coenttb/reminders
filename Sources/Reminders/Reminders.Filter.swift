public import Models
public import Reminder

extension Reminders {
    public enum Filter: Hashable, Sendable {
        case all
        case completed
        case flagged
        case scheduled
        case today
        case list(Models.List<Reminder>.ID)
        case tags(Set<Tag<Reminder>>)
    }
}
