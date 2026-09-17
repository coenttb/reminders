extension Reminders {
    public struct Overview: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Overview {
    public struct Client: Sendable {
        public var fetch: Fetch.Client

        public init(
            fetch: Fetch.Client
        ) {
            self.fetch = fetch
        }
    }
}
