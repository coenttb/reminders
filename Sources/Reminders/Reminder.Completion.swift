extension Reminder {
    /// Whether the reminder is done. The grace period after the tap, during which it can be
    /// undone, is the application's (`Completion.Pending`), not the reminder's.
    public enum Completion: Hashable, Sendable {
        case incomplete
        case completed
    }
}
