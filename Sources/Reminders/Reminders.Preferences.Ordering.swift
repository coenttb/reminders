public import Models

extension Reminders.Preferences {
    public enum Ordering {
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}

extension Reminders.Preferences.Ordering {
    public struct Request: Hashable, Sendable {
        public var ordering: Reminders.Ordering
        public var filter: Reminders.Filter

        public init(ordering: Reminders.Ordering, filter: Reminders.Filter) {
            self.ordering = ordering
            self.filter = filter
        }
    }
}
