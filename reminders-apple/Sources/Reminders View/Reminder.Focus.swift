public import Reminders

extension Reminder {
    public enum Focus: Hashable, Sendable {
        case title(Reminder.ID)
        case notes(Reminder.ID)
    }
}
