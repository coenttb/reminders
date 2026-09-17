extension Reminders {
    public enum Ordering: CaseIterable, Hashable, Sendable {
        case manual, dueDate, creationDate, priority, title
    }
}
