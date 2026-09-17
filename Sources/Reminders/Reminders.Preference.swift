extension Reminders {
    public struct Preference: Hashable, Sendable {
        public var ordering: Ordering
        public var showCompleted: Bool

        public init(ordering: Ordering, showCompleted: Bool) {
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}
