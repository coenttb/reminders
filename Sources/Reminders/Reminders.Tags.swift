extension Reminders {
    public struct Tags: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
