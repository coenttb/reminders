public import Foundation
import FoundationEssentials_Extensions

extension Reminders.Reminder {
    public static func isBlank(title: String) -> Bool { title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(title: title) }

    public var completed: Bool { completion == .completed }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due.map { Due.isPast($0, at: now, calendar: calendar) } ?? false }

    public mutating func set(due date: Date?) { due = Due.setting(due, date: date) }

    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) { due = Due.setting(due, hasTime: hasTime, at: now, calendar: calendar) }

    public mutating func set(datePreset preset: Due.Preset?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }

    public mutating func set(timePreset preset: Due.Preset.Time?, at now: Date, calendar: Calendar) { due = Due.applying(preset, to: due, at: now, calendar: calendar) }
}
