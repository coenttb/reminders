import Foundation
public import Organizing
public import Reminders
import Reminders_Interface
public import SQLiteData
import Tagged

extension Reminders.Overview.Request {
    @Selection
    struct Entry {
        let list: List<Reminder>.Record
        let count: Int
    }
}
