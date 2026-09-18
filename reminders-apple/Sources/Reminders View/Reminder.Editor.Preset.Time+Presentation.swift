public import Reminder
public import Foundation
import FoundationEssentials_Extensions
public import Reminders
public import Reminders_Feature

extension Reminder.Editor.Preset.Time {
    public var title: String {
        switch self {
        case .morning: "Morning"
        case .midday: "Midday"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .night: "Night"
        }
    }

    public func description(on day: Date, calendar: Calendar) -> String? {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day).flatMap { Reminder.Due.timeDescription(of: .moment($0), calendar: calendar) }
    }
}
