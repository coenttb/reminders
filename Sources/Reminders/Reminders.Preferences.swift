extension Reminders {
    public struct Preferences: Sendable {
        public var ordering: Ordering
        public var toggleShowCompleted: ToggleShowCompleted

        public init(
            ordering: Ordering,
            toggleShowCompleted: ToggleShowCompleted
        ) {
            self.ordering = ordering
            self.toggleShowCompleted = toggleShowCompleted
        }
    }
}
