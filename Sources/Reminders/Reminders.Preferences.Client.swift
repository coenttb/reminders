extension Reminders.Preferences {
    public struct Client: Sendable {
        public var ordering: @Sendable (Reminders.Ordering, _ filter: Reminders.Filter) throws -> Void
        public var toggleShowCompleted: @Sendable (_ filter: Reminders.Filter) throws -> Void

        public init(
            ordering: @escaping @Sendable (Reminders.Ordering, _ filter: Reminders.Filter) throws -> Void,
            toggleShowCompleted: @escaping @Sendable (_ filter: Reminders.Filter) throws -> Void
        ) {
            self.ordering = ordering
            self.toggleShowCompleted = toggleShowCompleted
        }
    }
}
