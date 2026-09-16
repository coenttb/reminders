extension Reminders {
    public struct Overview: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
