public import Foundation
import FoundationEssentials_Extensions

extension Reminder {
    public static func isBlank(title: String) -> Bool { title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(title: title) }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due?.isPast(at: now, calendar: calendar) ?? false }
}
