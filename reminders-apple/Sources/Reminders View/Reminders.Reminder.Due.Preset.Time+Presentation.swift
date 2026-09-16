public import Foundation
import FoundationEssentials_Extensions
public import Reminders

extension Reminders.Reminder.Due.Preset.Time {
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
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)?.formatted(Reminder.Due.style(date: .omitted, time: .shortened, calendar: calendar))
    }
}
