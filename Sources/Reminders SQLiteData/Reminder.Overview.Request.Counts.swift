import Foundation
import Organizing
import Reminders
import Reminders_Interface
public import SQLiteData
import Tagged

extension Reminders.Overview.Request {
    @Selection
    struct Counts {
        let all: Int
        let flagged: Int
        let scheduled: Int
        let today: Int
    }
}
