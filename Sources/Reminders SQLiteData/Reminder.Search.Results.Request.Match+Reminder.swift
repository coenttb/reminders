public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder {
    init(_ match: Reminder.Search.Results.Request.Match) {
        self.init(match.reminder, tags: Reminder.Record.tags(from: match.tags))
    }
}
