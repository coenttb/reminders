public import Foundation
public import Reminders

extension Reminders.Reminder.Record.Draft {
    public var completed: Bool { status != .incomplete }

    public var isBlank: Bool { Reminder.isBlank(title: title) }

    public mutating func set(due date: Date?) { due = Reminder.Due.setting(due, date: date) }

    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) { due = Reminder.Due.setting(due, hasTime: hasTime, at: now, calendar: calendar) }

    public mutating func set(datePreset preset: Reminder.Due.Preset?, at now: Date, calendar: Calendar) { due = Reminder.Due.applying(preset, to: due, at: now, calendar: calendar) }

    public mutating func set(timePreset preset: Reminder.Due.Preset.Time?, at now: Date, calendar: Calendar) { due = Reminder.Due.applying(preset, to: due, at: now, calendar: calendar) }
}
