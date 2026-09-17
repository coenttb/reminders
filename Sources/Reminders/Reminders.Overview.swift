extension Reminders {
    public struct Overview: Sendable {
        public var fetch: Fetch

        public init(
            fetch: Fetch
        ) {
            self.fetch = fetch
        }
    }
}
