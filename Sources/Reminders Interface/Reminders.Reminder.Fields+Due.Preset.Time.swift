public import Foundation
public import Reminders

extension Reminders.Reminder.Fields {
    public static func setting(_ fields: Self, timePreset preset: Reminders.Reminder.Due.Preset.Time?, at now: Date, calendar: Calendar) -> Self {
        var set = fields
        let day = fields.dueDate ?? now
        set.due = preset.map { .moment(calendar.date(bySettingHour: $0.hour, minute: 0, second: 0, of: day) ?? day) }
            ?? fields.due.map { .day(calendar.startOfDay(for: $0.date)) }
        return set
    }

    public mutating func set(timePreset preset: Reminders.Reminder.Due.Preset.Time?, at now: Date, calendar: Calendar) {
        self = Self.setting(self, timePreset: preset, at: now, calendar: calendar)
    }
}
