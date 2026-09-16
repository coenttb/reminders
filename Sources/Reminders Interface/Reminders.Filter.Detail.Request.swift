public import Foundation
public import Reminder
public import Reminders

extension Reminders.Filter.Detail {
    public struct Request: Hashable, Sendable {
        public var filter: Reminders.Filter?
        public var today: Range<Date>
        public var place: Reminder?
        public var limit: Int?

        public init(filter: Reminders.Filter?, today: Range<Date>, place: Reminder? = nil, limit: Int? = nil) {
            self.filter = filter
            self.today = today
            self.place = place
            self.limit = limit
        }
    }
}
