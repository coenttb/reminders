public import Foundation

extension Reminder.Due {
    public static func setting(_ due: Self?, date: Date?) -> Self? {
        date.map { Self($0, hasTime: due?.hasTime ?? false) }
    }

    public static func isPast(_ due: Self, at now: Date, calendar: Calendar) -> Bool {
        calendar.compare(due.date, to: now, toGranularity: .day) == .orderedAscending
    }
}
