extension Reminders {
    public struct Lists: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
