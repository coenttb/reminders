import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Search.Results {
    public struct Request {
        public var search: Reminder.Search
        public var limit: Int?

        public init(search: Reminder.Search, limit: Int? = nil) {
            self.search = search
            self.limit = limit
        }
    }
}
