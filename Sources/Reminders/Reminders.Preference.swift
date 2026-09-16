extension Reminders {
    public struct Preference: Hashable, Sendable {
        public var ordering: Ordering
        public var showCompleted: Bool

        public init(ordering: Ordering = .dueDate, showCompleted: Bool = false) {
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Preference {
    public static func `default`(for filter: Reminders.Filter) -> Self {
        Self(showCompleted: filter == .completed)
    }
}
