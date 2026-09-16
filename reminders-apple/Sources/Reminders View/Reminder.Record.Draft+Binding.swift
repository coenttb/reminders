import Foundation
import Reminder
import Reminders
import Reminders_SQL

extension Reminder.Record.Draft {
    subscript(dueOn now: Date, calendar calendar: Calendar) -> Bool {
        get { due != nil }
        set { set(due: newValue ? calendar.startOfDay(for: now) : nil) }
    }

    subscript(timeOn now: Date, calendar calendar: Calendar) -> Bool {
        get { hasTime }
        set { set(hasTime: newValue, at: now, calendar: calendar) }
    }

    subscript(repeatFrequency calendar: Calendar) -> Calendar.RecurrenceRule.Frequency? {
        get { repeats?.frequency }
        set { repeats = newValue.map { Calendar.RecurrenceRule(calendar: calendar, frequency: $0) } }
    }

    subscript(date fallback: Date) -> Date {
        get { due?.date ?? fallback }
        set { set(due: newValue) }
    }
}
