import Organizing
public import Reminders
import Tagged

extension Reminders.Reminder {
    public var tagLine: String { tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ") }
}
