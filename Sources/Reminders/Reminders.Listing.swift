extension Reminders {
    public struct Listing: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Listing {
    public struct Client: Sendable {
        public var fetch: Fetch.Client

        public init(
            fetch: Fetch.Client
        ) {
            self.fetch = fetch
        }
    }
}
