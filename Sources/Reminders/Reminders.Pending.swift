extension Reminders {
    public struct Pending: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
