public import Models

extension Reminders.Preferences.Client {
    public struct Ordering: Operation {
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Preferences.Client.Ordering {
    public struct Request: Hashable, Sendable {
        public var ordering: Reminders.Ordering
        public var filter: Reminders.Filter

        public init(ordering: Reminders.Ordering, filter: Reminders.Filter) {
            self.ordering = ordering
            self.filter = filter
        }
    }
}
