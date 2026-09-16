public import Organizing
public import Reminders
public import Reminders_Interface
public import StructuredQueries
public import Tagged

extension Reminders.Reminder {
    package init(_ match: Reminders.Search.Request.Match) {
        self.init(match.reminder, tags: Reminder.Record.tags(from: match.tags))
    }
}
