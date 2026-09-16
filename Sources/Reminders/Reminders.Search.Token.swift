public import Models
public import Reminder

extension Reminders.Search {
    public enum Token: Hashable, Sendable {
        case near(String)
        case tag(Tag<Reminder>)
    }
}
