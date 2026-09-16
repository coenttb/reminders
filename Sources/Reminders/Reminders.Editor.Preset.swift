public import Foundation
import FoundationEssentials_Extensions
import FoundationInternationalization_Extensions

extension Reminders.Editor {
    public enum Preset: CaseIterable, Hashable, Sendable {
        case today, tomorrow, thisWeekend, nextWeek
    }
}

extension Reminders.Editor.Preset {
    public static func date(for preset: Self, at now: Date, calendar: Calendar) -> Date {
        let today = calendar.startOfDay(for: now)
        let day: Date? = switch preset {
        case .today: today
        case .tomorrow: calendar.day(containing: now)?.upperBound
        case .thisWeekend: today.next(.saturday, in: calendar)
        case .nextWeek: today.next(.monday, in: calendar)
        }
        return day ?? today
    }

    public func date(at now: Date, calendar: Calendar) -> Date { Self.date(for: self, at: now, calendar: calendar) }
}
