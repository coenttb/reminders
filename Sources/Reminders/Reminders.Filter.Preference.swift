extension Reminders.Filter {
    public struct Preference: Hashable, Sendable {
        public var ordering: Reminders.Ordering
        public var showCompleted: Bool

        public init(ordering: Reminders.Ordering = .dueDate, showCompleted: Bool = false) {
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Filter.Preference {
    public static func `default`(for filter: Reminders.Filter) -> Self {
        Self(showCompleted: filter == .completed)
    }
}
