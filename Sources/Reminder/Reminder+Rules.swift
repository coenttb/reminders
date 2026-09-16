public import Foundation
import FoundationEssentials_Extensions

extension Reminder {
    public static func isBlank(title: String) -> Bool { title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(title: title) }

    public var completed: Bool { completion == .completed }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due.map { Due.isPast($0, at: now, calendar: calendar) } ?? false }

    public mutating func set(due date: Date?) { due = Due.setting(due, date: date) }
}
