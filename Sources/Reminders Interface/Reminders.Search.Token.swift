public import Organizing
public import Reminders
public import Tagged

extension Reminders.Search {
    public enum Token: Hashable, Sendable {
        case near(String)
        case tag(Tag<Reminder>.ID)
    }
}

extension Reminders.Search.Token: Identifiable {
    public var id: Self { self }
}
