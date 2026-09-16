public import Foundation

extension Reminders.Search {
    public struct View {
        public var query: Query
        public var window: Window<Query>
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(query: Query, window: Window<Query>, now: Date, calendar: Calendar, actions: Actions) {
            self.query = query
            self.window = window
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
