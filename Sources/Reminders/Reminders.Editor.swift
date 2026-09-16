extension Reminders {
    public struct Editor: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
