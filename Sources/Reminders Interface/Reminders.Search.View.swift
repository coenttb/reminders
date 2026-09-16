public import Foundation
public import Reminders

extension Reminders.Search {
    public struct View {
        public var search: Reminders.Search
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(search: Reminders.Search, now: Date, calendar: Calendar, actions: Actions) {
            self.search = search
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
