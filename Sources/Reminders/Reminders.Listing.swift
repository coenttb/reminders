extension Reminders {
    public struct Listing: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
