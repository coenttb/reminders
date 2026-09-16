public import Foundation
import FoundationEssentials_Extensions

extension Reminders.Reminder.Fields {
    public var due: Reminders.Reminder.Due? {
        get { dueDate.map { Reminders.Reminder.Due($0, hasTime: hasTime) } }
        set {
            dueDate = newValue?.date
            hasTime = newValue?.hasTime ?? false
        }
    }

    public static func isBlank(_ fields: Self) -> Bool { fields.title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(self) }

    public static func pastDue(_ fields: Self, at now: Date, calendar: Calendar) -> Bool {
        guard !fields.completed, let due = fields.dueDate else { return false }
        return calendar.compare(due, to: now, toGranularity: .day) == .orderedAscending
    }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { Self.pastDue(self, at: now, calendar: calendar) }

    public static func setting(_ fields: Self, due date: Date?) -> Self {
        var set = fields
        set.dueDate = date
        if date == nil { set.hasTime = false }
        return set
    }

    public mutating func set(due date: Date?) { self = Self.setting(self, due: date) }

    public static func setting(_ fields: Self, hasTime: Bool, at now: Date, calendar: Calendar) -> Self {
        var set = fields
        if hasTime {
            let day = fields.dueDate ?? now
            set.due = .moment(calendar.nextHour(after: now).flatMap { calendar.date(day: day, time: $0) } ?? day)
        } else {
            set.due = fields.dueDate.map { .day($0) }
        }
        return set
    }

    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) {
        self = Self.setting(self, hasTime: hasTime, at: now, calendar: calendar)
    }
}
