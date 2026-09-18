public import Reminder
public import Reminders
public import StructuredQueries

extension Reminder.Record.TableColumns {
    // A filter is a predicate over the rows.
    public func belongs(to filter: Reminders.Read.Filter) -> SQLQueryExpression<Bool> {
        switch filter {
        case .all: SQLQueryExpression("1")
        case let .list(id): SQLQueryExpression("\(listID.eq(id))")
        }
    }
}
