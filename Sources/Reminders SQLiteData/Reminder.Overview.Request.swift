public import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Overview {
    public struct Request {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }
    }
}
