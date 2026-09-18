public import Foundation
import Models
public import Reminder
public import Reminders
public import StructuredQueries

extension Reminder.Record.TableColumns {
    public var isCompleted: SQLQueryExpression<Bool> { SQLQueryExpression("\(completed.isNot(nil))") }

    public var isDeleted: SQLQueryExpression<Bool> { SQLQueryExpression("\(deleted.isNot(nil))") }
    public var isKept: SQLQueryExpression<Bool> { SQLQueryExpression("\(deleted.is(nil))") }

    public var isOpen: SQLQueryExpression<Bool> { SQLQueryExpression("\(!isCompleted && isKept)") }

    public var isScheduled: some QueryExpression<Bool> {
        isOpen && dueDate.isNot(nil)
    }

    // Due today or overdue: the stock Today list carries every open reminder due before tomorrow.
    public func isDue(by day: Range<Date>) -> some QueryExpression<Bool> {
        isOpen && dueDate.isNot(nil) && dueDate.lt(Date?.some(day.upperBound))
    }

    // Every screen but Recently Deleted reads the kept rows only.
    public func belongs(to filter: Reminders.Filter, today: Range<Date>) -> SQLQueryExpression<Bool> {
        switch filter {
        case .all: SQLQueryExpression("\(isKept)")
        case .completed: SQLQueryExpression("\(isKept && isCompleted)")
        case .flagged: SQLQueryExpression("\(isKept && flagged)")
        case let .list(id): SQLQueryExpression("\(isKept && listID.eq(id))")
        case .scheduled: SQLQueryExpression("\(isScheduled)")
        case let .tags(tags): SQLQueryExpression("\(isKept && Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(Array(tags)) }.exists())")
        case .today: SQLQueryExpression("\(isDue(by: today))")
        case .recentlyDeleted: SQLQueryExpression("\(isDeleted)")
        }
    }
}
