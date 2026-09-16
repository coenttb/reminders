public import Foundation
public import Reminder

extension Reminder.Record {
    public var completed: Bool { status != .incomplete }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due?.isPast(at: now, calendar: calendar) ?? false }
}
