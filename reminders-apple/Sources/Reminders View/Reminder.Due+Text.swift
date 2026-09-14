public import Foundation
public import Reminders
public import SwiftUI

extension Reminder {
    /// The due date as iOS 27 Reminders words it: Today, Tomorrow, Yesterday, a weekday
    /// within the week, otherwise a short date; the time follows when it matters.
    public func dueDescription(at now: Date) -> String? {
        guard let due, let day = dayDescription(at: now) else { return nil }
        return hasTime ? "\(day), \(due.formatted(date: .omitted, time: .shortened))" : day
    }

    /// The day alone, for the Date row's subtitle.
    public func dayDescription(at now: Date) -> String? {
        guard let due else { return nil }
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(due) {
            day = "Today"
        } else if calendar.isDateInTomorrow(due) {
            day = "Tomorrow"
        } else if calendar.isDateInYesterday(due) {
            day = "Yesterday"
        } else if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day, (2...6).contains(days) {
            day = due.formatted(.dateTime.weekday(.wide))
        } else {
            day = due.formatted(date: .abbreviated, time: .omitted)
        }
        return day
    }

    /// The time alone, for the Time row's subtitle.
    public func timeDescription() -> String? {
        guard let due, hasTime else { return nil }
        return due.formatted(date: .omitted, time: .shortened)
    }
}
