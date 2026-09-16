import Foundation
import Organizing
public import Reminders
import Tagged

extension Reminder {
    public var tagLine: String { tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ") }
}

extension Reminder {
    subscript(dueOn now: Date, calendar calendar: Calendar) -> Bool {
        get { due != nil }
        set { set(due: newValue ? calendar.startOfDay(for: now) : nil) }
    }

    subscript(timeOn now: Date, calendar calendar: Calendar) -> Bool {
        get { due?.hasTime == true }
        set { set(hasTime: newValue, at: now, calendar: calendar) }
    }

    subscript(date fallback: Date) -> Date {
        get { due?.date ?? fallback }
        set { set(due: newValue) }
    }
}
