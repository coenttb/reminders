extension Reminders {
    public struct Search: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
