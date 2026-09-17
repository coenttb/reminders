public import Models

extension Reminders.Preferences.Update {
    public struct Request: Hashable, Sendable {
        public var filter: Reminders.Filter
        public var change: Change

        public init(filter: Reminders.Filter, change: Change) {
            self.filter = filter
            self.change = change
        }
    }

    public enum Change: Hashable, Sendable {
        case ordering(Reminders.Ordering)
        case toggleShowCompleted
    }
}
