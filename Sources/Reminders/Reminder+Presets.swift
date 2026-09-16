public import Foundation
public import Reminder

extension Reminder {
    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) { due = Due.setting(due, hasTime: hasTime, at: now, calendar: calendar) }

    public mutating func set(datePreset preset: Due.Preset?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }

    public mutating func set(timePreset preset: Due.Preset.Time?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }
}
