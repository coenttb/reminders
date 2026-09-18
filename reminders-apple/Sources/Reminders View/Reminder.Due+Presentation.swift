public import Foundation
import FoundationEssentials_Extensions
public import Reminder

extension Reminder.Due {
    public static func description(of due: Self, at now: Date, calendar: Calendar) -> String {
        let day = dayDescription(of: due, at: now, calendar: calendar)
        return due.hasTime ? "\(day), \(timeDescription(of: due, calendar: calendar) ?? "")" : day
    }

    public func description(at now: Date, calendar: Calendar) -> String { Self.description(of: self, at: now, calendar: calendar) }

    // Today, Tomorrow, and Yesterday by word; every other day as the stock rows show it, a padded numeric date (16/09/2026).
    public static func dayDescription(of due: Self, at now: Date, calendar: Calendar, otherwise style: Date.FormatStyle.DateStyle? = nil) -> String {
        switch now.daysBetween(due.date, in: calendar) ?? 0 {
        case 0: "Today"
        case 1: "Tomorrow"
        case -1: "Yesterday"
        default: due.date.formatted(style.map { Self.style(date: $0, time: .omitted, calendar: calendar) } ?? Self.style(calendar: calendar).day(.twoDigits).month(.twoDigits).year())
        }
    }

    public func dayDescription(at now: Date, calendar: Calendar, otherwise style: Date.FormatStyle.DateStyle? = nil) -> String {
        Self.dayDescription(of: self, at: now, calendar: calendar, otherwise: style)
    }

    // Hours keep the locale's clock; a 24-hour clock pads to two digits (06:15), as the stock rows do.
    public static func timeDescription(of due: Self, calendar: Calendar) -> String? {
        due.hasTime ? due.date.formatted(style(calendar: calendar).hour(.conversationalTwoDigits(amPM: .abbreviated)).minute(.twoDigits)) : nil
    }

    public func timeDescription(calendar: Calendar) -> String? { Self.timeDescription(of: self, calendar: calendar) }

    static func style(date: Date.FormatStyle.DateStyle? = nil, time: Date.FormatStyle.TimeStyle? = nil, calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: time, calendar: calendar, timeZone: calendar.timeZone)
    }
}
