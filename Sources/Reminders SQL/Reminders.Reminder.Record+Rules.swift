public import Foundation
public import Reminders

extension Reminders.Reminder.Record {
    public var completed: Bool { status != .incomplete }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due.map { Reminder.Due.isPast($0, at: now, calendar: calendar) } ?? false }
}
