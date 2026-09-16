public import Foundation
public import Reminders

extension Reminders.Overview {
    /// The home screen as the app describes it: what it shows and what it can do. Its renderer
    /// holds the contents.
    public struct View {
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(now: Date, calendar: Calendar, actions: Actions) {
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
