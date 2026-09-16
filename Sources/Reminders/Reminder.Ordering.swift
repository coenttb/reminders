import Foundation

extension Reminder {
    /// The raw value is the stored key; the cases are in the stock menu's order.
    public enum Ordering: String, CaseIterable, Hashable, Sendable {
        case manual, dueDate, creationDate, priority, title
    }
}

extension Reminder.Ordering {
    /// The order a detail shows under the ordering, ties broken by position as the manual
    /// order has it: due dates ascending with none last, creation dates ascending, priorities
    /// descending then flagged first, titles as the locale compares them ignoring case.
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
