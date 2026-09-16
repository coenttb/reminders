extension Reminders.Listing {
    public struct Client: Sendable {
        public var fetch: Fetch

        public init(
            fetch: Fetch
        ) {
            self.fetch = fetch
        }
    }
}
