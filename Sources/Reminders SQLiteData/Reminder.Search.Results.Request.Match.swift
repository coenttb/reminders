import Foundation
public import Organizing
public import Reminders
import Reminders_Interface
public import SQLiteData
import Tagged

extension Reminders.Search.Request {
    @Selection
    struct Match {
        let reminder: Reminder.Record
        let tags: String?
        let list: List<Reminder>.Record
    }
}
