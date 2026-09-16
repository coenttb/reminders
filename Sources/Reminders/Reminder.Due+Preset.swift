public import Foundation
public import Reminder
import FoundationEssentials_Extensions

extension Reminder.Due {
    public static func applying(_ preset: Preset?, to due: Self?, at now: Date, calendar: Calendar) -> Self? {
        guard let preset else { return nil }
        let day = preset.date(at: now, calendar: calendar)
        return switch due {
        case let .moment(time)?: .moment(calendar.date(day: day, time: time) ?? day)
        case .day?, nil: .day(day)
        }
    }
}
