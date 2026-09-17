public import Models

extension Reminders.Preferences {
    public struct ToggleShowCompleted: Sendable {
        public typealias Request = Reminders.Filter
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
