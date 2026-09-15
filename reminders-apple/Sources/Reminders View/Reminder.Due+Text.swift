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
        // Relative to the given now, not the wall clock, so the wording is testable and stable.
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2...6: return due.formatted(.dateTime.weekday(.wide))
        default: return due.formatted(date: .abbreviated, time: .omitted)
        }
    }

    /// The time alone, for the Time row's subtitle.
    public func timeDescription() -> String? {
        guard let due, hasTime else { return nil }
        return due.formatted(date: .omitted, time: .shortened)
    }
}
