extension Reminders {
    public struct Preferences: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
