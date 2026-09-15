public import Foundation
import FoundationEssentials_Extensions
import FoundationInternationalization_Extensions
public import Reminders

extension Reminder.Due {
    /// The days the inline Date chip offers.
    public enum Preset: CaseIterable, Hashable, Sendable {
        case today, tomorrow, thisWeekend, nextWeek
    }
}

extension Reminder.Due.Preset {
    /// The start of the preset's day: today, tomorrow, the coming Saturday, the coming Monday;
    /// today when the calendar cannot say.
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

extension Reminder {
    /// A preset day keeps the time of day if one was set; none clears the date and the time.
    public static func setting(_ reminder: Self, datePreset preset: Due.Preset?, at now: Date, calendar: Calendar) -> Self {
        guard let preset else { return setting(reminder, due: nil) }
        var set = reminder
        let day = preset.date(at: now, calendar: calendar)
        set.due = switch reminder.due {
        case let .moment(time)?: .moment(calendar.date(day: day, time: time) ?? day)
        case .day?, nil: .day(day)
        }
        return set
    }

    public mutating func set(datePreset preset: Due.Preset?, at now: Date, calendar: Calendar) {
        self = Self.setting(self, datePreset: preset, at: now, calendar: calendar)
    }
}
