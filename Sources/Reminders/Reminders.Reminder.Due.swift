public import Foundation

extension Reminders.Reminder {
    public enum Due: Hashable, Sendable {
        case day(Date)
        case moment(Date)
    }
}

extension Reminders.Reminder.Due {
    public init(_ date: Date, hasTime: Bool) {
        self = hasTime ? .moment(date) : .day(date)
    }

    public var date: Date {
        switch self {
        case let .day(date), let .moment(date): date
        }
    }

    public var hasTime: Bool {
        if case .moment = self { true } else { false }
    }
}
