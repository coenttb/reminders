public import Foundation
import FoundationEssentials_Extensions
public import Reminders

extension Reminders.Reminder.Fields {
    public static func setting(_ fields: Self, datePreset preset: Reminders.Reminder.Due.Preset?, at now: Date, calendar: Calendar) -> Self {
        guard let preset else { return setting(fields, due: nil) }
        var set = fields
        let day = preset.date(at: now, calendar: calendar)
        set.due = switch fields.due {
        case let .moment(time)?: .moment(calendar.date(day: day, time: time) ?? day)
        case .day?, nil: .day(day)
        }
        return set
    }

    public mutating func set(datePreset preset: Reminders.Reminder.Due.Preset?, at now: Date, calendar: Calendar) {
        self = Self.setting(self, datePreset: preset, at: now, calendar: calendar)
    }
}
