extension Reminders.Reminder {
    public enum Priority: Int, CaseIterable, Hashable, Sendable {
        case low = 1
        case medium
        case high
    }
}
