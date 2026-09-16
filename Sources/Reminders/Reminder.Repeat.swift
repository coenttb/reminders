extension Reminder {
    public enum Repeat: String, CaseIterable, Hashable, Sendable {
        case never, daily, weekly, monthly, yearly
    }
}
