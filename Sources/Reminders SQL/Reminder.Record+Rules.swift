public import Foundation
public import Reminder

extension Reminder.Record {
    public func pastDue(at now: Date, calendar: Calendar) -> Bool { !completed && due?.isPast(at: now, calendar: calendar) ?? false }
}
