import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Search.Results.Request {
    @Selection
    struct Match {
        let reminder: Reminder.Record
        let tags: String?
        let list: List<Reminder>.Record
    }
}
