public import Foundation

extension Reminder {
    /// When a reminder is due: some time on a day, or at a moment on it. A time is never
    /// without a day, so a reminder cannot hold one.
    public enum Due: Hashable, Sendable {
        case day(Date)
        case moment(Date)
    }
}

extension Reminder.Due {
    public init(_ date: Date, hasTime: Bool) {
        self = hasTime ? .moment(date) : .day(date)
    }

    public var date: Date {
        switch self {
        case let .day(date), let .moment(date): date
        }
    }

    /// Whether the time of day matters; without it the reminder is due some time that day.
    public var hasTime: Bool {
        if case .moment = self { true } else { false }
    }
}

