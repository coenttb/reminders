public import Foundation
public import Reminders

extension Reminders.Reminder.Due.Preset {
    public enum Time: Int, CaseIterable, Hashable, Sendable {
        case morning = 9, midday = 12, afternoon = 15, evening = 18, night = 21

        public var hour: Int { rawValue }
    }
}

extension Reminders.Reminder {
    public static func setting(_ reminder: Self, timePreset preset: Due.Preset.Time?, at now: Date, calendar: Calendar) -> Self {
        var set = reminder
        let day = reminder.due?.date ?? now
        set.due = preset.map { .moment(calendar.date(bySettingHour: $0.hour, minute: 0, second: 0, of: day) ?? day) }
            ?? reminder.due.map { .day(calendar.startOfDay(for: $0.date)) }
        return set
    }

    public mutating func set(timePreset preset: Due.Preset.Time?, at now: Date, calendar: Calendar) {
        self = Self.setting(self, timePreset: preset, at: now, calendar: calendar)
    }
}
