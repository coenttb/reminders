public import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder

extension Reminders {
    // Where a row sits on a screen: the stock smart lists section by day and by time of day, the lists that
    // gather rows from every list section by list, and a list shows its rows plainly.
    public enum Section: Hashable, Comparable, Sendable {
        case rows
        case list(Models.List<Reminder>.ID)
        // Overdue rows: Today gathers them in one section without a header (no day), Scheduled lists every overdue day.
        case overdue(day: Date?)
        // Today: all-day rows without a header, then the parts of the day.
        case allDay, morning, afternoon, tonight
        // Scheduled: today, tomorrow, the five days after, the rest of the month, then months.
        case today, tomorrow, day(Date), restOfMonth, month(Date)
        // Completed: today, then each of the previous seven days, then months, the newest first.
        case previous(day: Date), earlier(month: Date)
    }
}

extension Reminders.Section {
    public static let afternoonHour = 12
    public static let tonightHour = 18
    public static let daysAfterTomorrow = 5
    public static let monthsAhead = 12
    public static let previousDays = 7

    // The sections a screen lists before any rows are read; the ones that come from the rows (overdue days,
    // months beyond the year) are added by the fold in order.
    public static func sections(for filter: Reminders.Filter, at now: Date, calendar: Calendar) -> [Self] {
        switch filter {
        case .today:
            return [.overdue(day: nil), .allDay, .morning, .afternoon, .tonight]
        case .scheduled:
            let today = calendar.startOfDay(for: now)
            let days = (2...(daysAfterTomorrow + 1)).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }.map(Self.day)
            let months = (1...monthsAhead).compactMap { calendar.date(byAdding: .month, value: $0, to: today)?.firstDayOfMonth(in: calendar) }.map(Self.month)
            return [.today, .tomorrow] + days + [.restOfMonth] + months
        case .completed:
            return [.today]
        case .all, .flagged, .list, .recentlyDeleted, .tags:
            return []
        }
    }

    // The section a row belongs to on a screen, by its due date; a screen without date sections keys by list or not at all.
    public static func section(of reminder: Reminder, in filter: Reminders.Filter, at now: Date, calendar: Calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        if filter == .completed {
            guard let completed = reminder.completed else { return .rows }
            switch today.daysBetween(completed, in: calendar) ?? 0 {
            case 0...: return .today
            case (-previousDays)..<0: return .previous(day: calendar.startOfDay(for: completed))
            default: return .earlier(month: completed.firstDayOfMonth(in: calendar) ?? completed)
            }
        }
        guard let due = reminder.due else { return filter.groupsByList ? .list(reminder.list) : .rows }
        let days = today.daysBetween(due.date, in: calendar) ?? 0
        switch filter {
        case .today:
            if days < 0 { return .overdue(day: nil) }
            return due.hasTime ? part(containing: due.date, calendar: calendar) : .allDay
        case .scheduled:
            switch days {
            case ..<0: return .overdue(day: calendar.startOfDay(for: due.date))
            case 0: return .today
            case 1: return .tomorrow
            case 2...(daysAfterTomorrow + 1): return .day(calendar.startOfDay(for: due.date))
            default:
                return calendar.isDate(due.date, equalTo: today, toGranularity: .month) ? .restOfMonth : .month(due.date.firstDayOfMonth(in: calendar) ?? due.date)
            }
        case .all, .flagged, .tags:
            return .list(reminder.list)
        case .completed, .list, .recentlyDeleted:
            return .rows
        }
    }

    public var isPreviousDay: Bool {
        if case .previous = self { true } else { false }
    }

    // Morning, afternoon, or tonight: the part of the day a moment falls in.
    public static func part(containing date: Date, calendar: Calendar) -> Self {
        let hour = calendar.component(.hour, from: date)
        return hour < afternoonHour ? .morning : hour < tonightHour ? .afternoon : .tonight
    }

    public func contains(_ reminder: Reminder, in filter: Reminders.Filter, at now: Date, calendar: Calendar) -> Bool {
        Self.section(of: reminder, in: filter, at: now, calendar: calendar) == self
    }

    // The order the sections take on a screen: overdue days by day, then the skeleton, days and months by
    // date; the Completed screen runs backwards, so its days and months are keyed by the time until them.
    public var order: (Int, TimeInterval) {
        switch self {
        case .rows, .list: (0, -.infinity)
        case let .overdue(day): (0, day?.timeIntervalSinceReferenceDate ?? -.infinity)
        case .allDay: (1, -.infinity)
        case .morning: (2, -.infinity)
        case .afternoon: (3, -.infinity)
        case .tonight: (4, -.infinity)
        case .today: (1, -.infinity)
        case .tomorrow: (2, -.infinity)
        case let .day(day): (3, day.timeIntervalSinceReferenceDate)
        case .restOfMonth: (4, -.infinity)
        case let .month(month): (5, month.timeIntervalSinceReferenceDate)
        case let .previous(day): (6, -day.timeIntervalSinceReferenceDate)
        case let .earlier(month): (7, -month.timeIntervalSinceReferenceDate)
        }
    }

    // The date a row started from this section takes.
    public func due(at now: Date, calendar: Calendar) -> Reminder.Due? {
        let today = calendar.startOfDay(for: now)
        func moment(_ hour: Int) -> Reminder.Due? { calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today).map(Reminder.Due.moment) }
        switch self {
        case .rows, .list, .overdue, .previous, .earlier: return nil
        case .allDay, .today: return .day(today)
        case .morning: return moment(9)
        case .afternoon: return moment(Self.afternoonHour)
        case .tonight: return moment(Self.tonightHour)
        case .tomorrow: return calendar.day(containing: now).map { .day($0.upperBound) }
        case let .day(day): return .day(day)
        case .restOfMonth, .month: return nil
        }
    }

    // The date a row dropped onto this section takes: its day, keeping the row's time of day; a part of the
    // day sets the hour. Sections that are not a date (overdue, months, lists) take no drops.
    public func due(moving due: Reminder.Due?, at now: Date, calendar: Calendar) -> Reminder.Due? {
        guard let target = self.due(at: now, calendar: calendar) else { return nil }
        switch self {
        case .morning, .afternoon, .tonight:
            return target
        default:
            guard let due, due.hasTime else { return target }
            let time = calendar.dateComponents([.hour, .minute], from: due.date)
            return calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: target.date).map(Reminder.Due.moment) ?? target
        }
    }

    public var acceptsDrops: Bool {
        switch self {
        case .allDay, .morning, .afternoon, .tonight, .today, .tomorrow, .day: true
        case .rows, .list, .overdue, .restOfMonth, .month, .previous, .earlier: false
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order.0 != rhs.order.0 ? lhs.order.0 < rhs.order.0 : lhs.order.1 < rhs.order.1
    }
}
