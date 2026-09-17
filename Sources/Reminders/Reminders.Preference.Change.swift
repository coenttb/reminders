public import Models

extension Reminders.Preference {
    public enum Change: Hashable, Sendable {
        case ordering(Reminders.Ordering)
        case toggleShowCompleted
    }
}
