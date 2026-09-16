import Foundation

extension Reminders {
    public enum Ordering: String, CaseIterable, Hashable, Sendable {
        case manual, dueDate, creationDate, priority, title
    }
}

extension Reminders.Ordering {
    public static func areInIncreasingOrder(_ lhs: Reminder, _ rhs: Reminder, for ordering: Self) -> Bool {
        switch ordering {
        case .manual:
            lhs.position < rhs.position
        case .dueDate:
            switch (lhs.due?.date, rhs.due?.date) {
            case let (l?, r?) where l != r: l < r
            case (nil, .some): false
            case (.some, nil): true
            default: lhs.position < rhs.position
            }
        case .creationDate:
            lhs.created != rhs.created ? lhs.created < rhs.created : lhs.position < rhs.position
        case .priority:
            if lhs.priority != rhs.priority {
                (lhs.priority?.rawValue ?? 0) > (rhs.priority?.rawValue ?? 0)
            } else if lhs.flagged != rhs.flagged {
                lhs.flagged
            } else {
                lhs.position < rhs.position
            }
        case .title:
            switch lhs.title.localizedCaseInsensitiveCompare(rhs.title) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: lhs.position < rhs.position
            }
        }
    }

    public func areInIncreasingOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        Self.areInIncreasingOrder(lhs, rhs, for: self)
    }
}
