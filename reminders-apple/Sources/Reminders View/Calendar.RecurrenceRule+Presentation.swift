public import Foundation
public import Reminder

extension Reminder {
    public static let repeatOptions: [Calendar.RecurrenceRule.Frequency] = [.daily, .weekly, .monthly, .yearly]
}

extension Calendar.RecurrenceRule.Frequency {
    public var title: String {
        switch self {
        case .minutely: "Minutely"
        case .hourly: "Hourly"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        @unknown default: "Repeat"
        }
    }
}

extension Calendar.RecurrenceRule {
    public var title: String { frequency.title }
}
