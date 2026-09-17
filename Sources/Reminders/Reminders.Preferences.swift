extension Reminders {
    public struct Preferences: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Preferences {
    public struct Client: Sendable {
        public var ordering: Ordering.Client
        public var toggleShowCompleted: ToggleShowCompleted.Client

        public init(
            ordering: Ordering.Client,
            toggleShowCompleted: ToggleShowCompleted.Client
        ) {
            self.ordering = ordering
            self.toggleShowCompleted = toggleShowCompleted
        }
    }
}
