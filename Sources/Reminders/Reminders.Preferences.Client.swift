extension Reminders.Preferences {
    public struct Client: Sendable {
        public var set: @Sendable (Reminders.Preference, _ filter: Reminders.Filter) throws -> Void

        public init(set: @escaping @Sendable (Reminders.Preference, _ filter: Reminders.Filter) throws -> Void) {
            self.set = set
        }
    }
}
