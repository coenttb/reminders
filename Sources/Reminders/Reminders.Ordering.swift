extension Reminders {
    public enum Ordering: String, CaseIterable, Hashable, Sendable {
        case manual, dueDate, creationDate, priority, title
    }
}
