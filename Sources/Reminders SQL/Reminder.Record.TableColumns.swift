public import Foundation
import Models
public import Reminder
public import Reminders
public import StructuredQueries

extension Reminder.Record.TableColumns {
    public var isCompleted: SQLQueryExpression<Bool> { SQLQueryExpression("\(completed.eq(true))") }

    public var isScheduled: some QueryExpression<Bool> {
        !isCompleted && dueDate.isNot(nil)
    }

    // Due today or overdue: the stock Today list carries every open reminder due before tomorrow.
    public func isDue(by day: Range<Date>) -> some QueryExpression<Bool> {
        !isCompleted && dueDate.isNot(nil) && dueDate.lt(Date?.some(day.upperBound))
    }

    public func belongs(to filter: Reminders.Filter, today: Range<Date>) -> SQLQueryExpression<Bool> {
        switch filter {
        case .all: SQLQueryExpression("1")
        case .completed: SQLQueryExpression("\(isCompleted)")
        case .flagged: SQLQueryExpression("\(flagged)")
        case let .list(id): SQLQueryExpression("\(listID.eq(id))")
        case .scheduled: SQLQueryExpression("\(isScheduled)")
        case let .tags(tags): SQLQueryExpression("\(Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(Array(tags)) }.exists())")
        case .today: SQLQueryExpression("\(isDue(by: today))")
        }
    }
}
