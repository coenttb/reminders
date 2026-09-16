import Organizing
public import Reminders
public import Reminders_SQL
import Tagged

extension Reminders.Reminder.Record.Row {
    public var tagLine: String { tags.map(Tag<Reminder>.ID.init).sorted().map(Tag<Reminder>.hashtag).joined(separator: " ") }
}
