public import Foundation
import FoundationEssentials_Extensions

extension Reminders.Reminder.Due {
    public static func setting(_ due: Self?, date: Date?) -> Self? {
        date.map { Self($0, hasTime: due?.hasTime ?? false) }
    }

    public static func setting(_ due: Self?, hasTime: Bool, at now: Date, calendar: Calendar) -> Self? {
        if hasTime {
            let day = due?.date ?? now
            return .moment(calendar.nextHour(after: now).flatMap { calendar.date(day: day, time: $0) } ?? day)
        }
        return due.map { .day($0.date) }
    }

    public static func isPast(_ due: Self, at now: Date, calendar: Calendar) -> Bool {
        calendar.compare(due.date, to: now, toGranularity: .day) == .orderedAscending
    }
}
