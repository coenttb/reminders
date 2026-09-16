public import Models
public import Reminder
public import Tagged

extension Reminders.Search {
    public enum Token: Hashable, Sendable {
        case near(String)
        case tag(Tag<Reminder>.ID)
    }
}
