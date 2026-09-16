public import Foundation
public import Reminders

extension Reminders.Search {
    /// The search results as the app describes them: the search they answer and what they can
    /// do. Its renderer holds the contents.
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
