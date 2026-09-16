import Foundation
import Organizing
import Reminders
import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Overview.Request {
    @Selection
    struct Counts {
        let all: Int
        let flagged: Int
        let scheduled: Int
        let today: Int
    }
}
