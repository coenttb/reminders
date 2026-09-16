import Organizing
import Reminders
import Reminders_Interface
import SQLiteData
import Tagged

extension Reminder {
    init(_ match: Reminders.Search.Request.Match) {
        self.init(match.reminder, tags: Reminder.Record.tags(from: match.tags))
    }
}
