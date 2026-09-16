import Foundation
public import Organizing
public import Reminders
import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Overview.Request {
    @Selection
    struct Entry {
        let list: List<Reminder>.Record
        let count: Int
    }
}
