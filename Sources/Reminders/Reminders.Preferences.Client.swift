extension Reminders.Preferences {
    public struct Client: Sendable {
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
