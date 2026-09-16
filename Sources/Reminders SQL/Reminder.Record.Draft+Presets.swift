public import Foundation
public import Reminder
public import Reminders

extension Reminder.Record.Draft {
    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) { due = Reminder.Due.setting(due, hasTime: hasTime, at: now, calendar: calendar) }

    public mutating func set(datePreset preset: Reminder.Due.Preset?, at now: Date, calendar: Calendar) { due = Reminder.Due.applying(preset, to: due, at: now, calendar: calendar) }

    public mutating func set(timePreset preset: Reminder.Due.Preset.Time?, at now: Date, calendar: Calendar) { due = Reminder.Due.applying(preset, to: due, at: now, calendar: calendar) }
}
