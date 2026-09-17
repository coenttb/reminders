public import Reminders
public import Foundation
public import Reminder

extension Reminder {
    public mutating func set(due date: Date?) { due = Due.setting(due, date: date) }

    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) { due = Due.setting(due, hasTime: hasTime, at: now, calendar: calendar) }

    public mutating func set(datePreset preset: Reminder.Editor.Preset?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }

    public mutating func set(timePreset preset: Reminder.Editor.Preset.Time?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }
}
