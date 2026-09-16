import Foundation
import Organizing
public import Reminders
public import Reminders_Application
import SQLiteData
import Tagged

extension Reminder.Search.Results {
    public struct Request: Hashable, Sendable {
        public var search: Reminder.Search
        public var limit: Int?

        public init(search: Reminder.Search, limit: Int? = nil) {
            self.search = search
            self.limit = limit
        }
    }
}
