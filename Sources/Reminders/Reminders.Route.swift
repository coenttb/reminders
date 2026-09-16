public import CasePaths
public import Reminder

extension Reminders {
    @CasePathable
    public enum Route: Hashable, Sendable {
        case overview
        case selection(Selection)
        case reminder(Reminder.ID)
    }
}
