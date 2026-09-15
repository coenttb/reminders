public import Reminders

extension Reminder.Filter {
    /// How a filter sorts and whether it shows completed reminders; persisted per filter.
    public struct Preference: Hashable, Sendable {
        public var ordering: Reminder.Ordering
        public var showCompleted: Bool

        public init(ordering: Reminder.Ordering = .dueDate, showCompleted: Bool = false) {
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}

extension Reminder.Filter.Preference {
    /// Completed shows completed reminders; every other filter hides them until asked.
    public static func `default`(for filter: Reminder.Filter) -> Self {
        Self(showCompleted: filter == .completed)
    }
}

extension Reminder.Filter {
    public var defaultPreference: Preference { Preference.default(for: self) }
}
