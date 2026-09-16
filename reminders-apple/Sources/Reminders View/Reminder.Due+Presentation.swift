public import Foundation
import FoundationEssentials_Extensions
public import Reminder

extension Reminder.Due {
    public static func description(of due: Self, at now: Date, calendar: Calendar) -> String {
        let day = dayDescription(of: due, at: now, calendar: calendar)
        return due.hasTime ? "\(day), \(due.date.formatted(Self.style(date: .omitted, time: .shortened, calendar: calendar)))" : day
    }

    public func description(at now: Date, calendar: Calendar) -> String { Self.description(of: self, at: now, calendar: calendar) }

    public static func dayDescription(of due: Self, at now: Date, calendar: Calendar) -> String {
        switch now.daysBetween(due.date, in: calendar) ?? 0 {
        case 0: "Today"
        case 1: "Tomorrow"
        case -1: "Yesterday"
        case 2...6: due.date.formatted(style(calendar: calendar).weekday(.wide))
        default: due.date.formatted(style(date: .abbreviated, time: .omitted, calendar: calendar))
        }
    }

    public func dayDescription(at now: Date, calendar: Calendar) -> String { Self.dayDescription(of: self, at: now, calendar: calendar) }

    public static func timeDescription(of due: Self, calendar: Calendar) -> String? {
        due.hasTime ? due.date.formatted(style(date: .omitted, time: .shortened, calendar: calendar)) : nil
    }

    public func timeDescription(calendar: Calendar) -> String? { Self.timeDescription(of: self, calendar: calendar) }

    static func style(date: Date.FormatStyle.DateStyle? = nil, time: Date.FormatStyle.TimeStyle? = nil, calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: time, calendar: calendar, timeZone: calendar.timeZone)
    }
}
