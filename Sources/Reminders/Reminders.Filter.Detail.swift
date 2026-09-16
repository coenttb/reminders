extension Reminders.Filter {
    public struct Detail: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
