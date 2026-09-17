public import Foundation
public import Models

extension Reminders {
    public enum Completed: Hashable, Sendable {
        case filter(Reminders.Filter, today: Range<Date>)
        case search(Reminders.Search.Query, dueBefore: Date?)
    }
}
