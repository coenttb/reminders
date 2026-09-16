import Organizing
public import Reminders
public import Reminders_SQL
import Tagged

extension Reminders.Reminder.Record.Row {
    public var tagLine: String {
        let ids: [Tag<Reminder>.ID] = tags.map { Tag<Reminder>.ID($0) }
        return ids.sorted().map { Tag<Reminder>.hashtag($0) }.joined(separator: " ")
    }
}
