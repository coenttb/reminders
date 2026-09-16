public import Foundation
import FoundationEssentials_Extensions
public import Reminder

extension Reminder.Due {
    public static func setting(_ due: Self?, hasTime: Bool, at now: Date, calendar: Calendar) -> Self? {
        if hasTime {
            let day = due?.date ?? now
            return .moment(calendar.nextHour(after: now).flatMap { calendar.date(day: day, time: $0) } ?? day)
        }
        return due.map { .day($0.date) }
    }
}
