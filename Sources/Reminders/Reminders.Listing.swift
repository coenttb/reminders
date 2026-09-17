extension Reminders {
    public struct Listing: Sendable {
        public var fetch: Fetch

        public init(
            fetch: Fetch
        ) {
            self.fetch = fetch
        }
    }
}
