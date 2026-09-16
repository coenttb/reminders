public import Foundation
import FoundationEssentials_Extensions
import FoundationInternationalization_Extensions
public import Reminders

extension Reminders.Reminder {
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
