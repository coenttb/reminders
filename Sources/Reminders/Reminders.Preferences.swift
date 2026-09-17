extension Reminders {
    public struct Preferences: Sendable {
        public var update: Update

        public init(update: Update) {
            self.update = update
        }
    }
}
