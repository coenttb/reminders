import Foundation
import Reminders

extension Reminders.Reminder.Fields {
    subscript(dueOn now: Date, calendar calendar: Calendar) -> Bool {
        get { dueDate != nil }
        set { set(due: newValue ? calendar.startOfDay(for: now) : nil) }
    }

    subscript(timeOn now: Date, calendar calendar: Calendar) -> Bool {
        get { hasTime }
        set { set(hasTime: newValue, at: now, calendar: calendar) }
    }

    subscript(date fallback: Date) -> Date {
        get { dueDate ?? fallback }
        set { set(due: newValue) }
    }
}
