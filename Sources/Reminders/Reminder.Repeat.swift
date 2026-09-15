extension Reminder {
    /// How often the reminder recurs; stored and shown, not yet scheduled.
    public enum Repeat: String, CaseIterable, Hashable, Sendable {
        case never, daily, weekly, monthly, yearly
    }
}
