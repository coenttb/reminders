import Organizing
import Reminders
import Reminders_Application
import SQLiteData
import Tagged

extension Reminder {
    init(_ match: Reminder.Search.Results.Request.Match) {
        self.init(match.reminder, tags: Reminder.Record.tags(from: match.tags))
    }
}
