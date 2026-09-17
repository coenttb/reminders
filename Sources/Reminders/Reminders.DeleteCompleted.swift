public import Foundation
public import Models

extension Reminders.DeleteCompleted {
    public enum Request: Hashable, Sendable {
        case filter(Reminders.Filter, today: Range<Date>)
        case search(Reminders.Search.Query, dueBefore: Date?)
    }
}
