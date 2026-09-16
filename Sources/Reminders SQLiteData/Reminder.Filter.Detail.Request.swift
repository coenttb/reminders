public import Foundation
import Organizing
public import Reminders
public import Reminders_Application
import SQLiteData
import Tagged

extension Reminder.Filter.Detail {
    public struct Request: Hashable, Sendable {
        public var filter: Reminder.Filter?
        public var today: Range<Date>
        public var place: Reminder?
        public var limit: Int?

        public init(filter: Reminder.Filter?, today: Range<Date>, place: Reminder? = nil, limit: Int? = nil) {
            self.filter = filter
            self.today = today
            self.place = place
            self.limit = limit
        }
    }
}
