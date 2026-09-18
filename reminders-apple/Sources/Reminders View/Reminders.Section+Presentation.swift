public import Foundation
public import Reminders
public import SwiftUI

extension Reminders.Section {
    // The stock headers: a title for the named sections, a day line for the day ones, a month name for the months.
    public enum Header: Hashable, Sendable {
        case none
        case title(String)
        case part(String)
        case day(Date)
        case month(Date)
        case restOfMonth
        case tomorrow
    }

    public var header: Header {
        switch self {
        case .rows, .list, .overdue(day: nil), .allDay: .none
        case .morning: .part("Morning")
        case .afternoon: .part("Afternoon")
        case .tonight: .part("Tonight")
        case let .overdue(day?): .day(day)
        case .today: .title("Today")
        case .tomorrow: .tomorrow
        case let .day(day): .day(day)
        case .restOfMonth: .restOfMonth
        case let .month(month): .month(month)
        }
    }

    // Overdue days share one title above the first of them.
    public var isOverdueDay: Bool {
        if case .overdue(day: .some) = self { true } else { false }
    }

    public var isDay: Bool {
        if case .day = self { true } else { isOverdueDay }
    }

    // A day section shows the time alone; the header-less overdue group on Today keeps its date.
    public var showsTimeAlone: Bool {
        self != .overdue(day: nil)
    }

    // The sections a row can be started in from the screen itself.
    public func offersAdd(in sections: [Reminders.Page.Section], at now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .today, .tomorrow: true
        case .morning, .afternoon, .tonight:
            // The circle follows the last part of the day with rows; with none, the part the clock is in.
            (sections.last { [.morning, .afternoon, .tonight].contains($0.key) && !$0.rows.isEmpty }?.key ?? Reminders.Section.part(containing: now, calendar: calendar)) == self
        default: false
        }
    }
}

extension Reminders.Section.Header {
    @ViewBuilder public func view(month calendar: Calendar, now: Date, empty: Bool) -> some View {
        switch self {
        case .none:
            EmptyView()
        case let .title(title):
            Text(title).font(.title2.weight(.bold)).foregroundStyle(Color.primary)
        case let .part(part):
            Text(part).font(.headline).foregroundStyle(empty ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.secondary))
        case .tomorrow:
            Text("Tomorrow").font(.headline).foregroundStyle(.secondary)
        case let .day(day):
            let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
            (Text(day.formatted(style.weekday(.abbreviated))).fontWeight(.semibold) + Text(" " + day.formatted(style.day().month(.abbreviated))))
                .font(.subheadline)
                .foregroundStyle(empty ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.secondary))
        case .restOfMonth:
            Text("Rest of " + now.formatted(Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.wide)))
                .font(.title2.weight(.bold)).foregroundStyle(.tertiary)
        case let .month(month):
            // The year is named once the months leave this one, as the stock list does (October … January 2027).
            let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.wide)
            Text(month.formatted(calendar.isDate(month, equalTo: now, toGranularity: .year) ? style : style.year()))
                .font(.title2.weight(.bold)).foregroundStyle(.tertiary)
        }
    }
}
