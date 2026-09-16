public import Foundation
import Organizing
public import Reminders
public import Reminders_Application
import SQLiteData
import Tagged

extension Reminder.Overview {
    public struct Request: Hashable, Sendable {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }
    }
}
