extension Reminders {
    public struct Restoration: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
