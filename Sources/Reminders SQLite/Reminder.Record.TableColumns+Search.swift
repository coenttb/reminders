import Foundation
import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.TableColumns {
    // The rows whose text matches the terms, through the full-text index, and that carry the tags.
    public func matches(_ query: Reminders.Query) -> SQLQueryExpression<Bool> {
        var predicate = SQLQueryExpression<Bool>("\(isKept)")
        if let pattern = Reminder.Record.Text.pattern(query.terms) {
            predicate = SQLQueryExpression("\(predicate) AND (\(rowid.in(Reminder.Record.Text.where { $0.match(pattern) }.select(\.rowid))))")
        }
        for tag in query.tags.sorted() {
            predicate = SQLQueryExpression("\(predicate) AND (\(Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()))")
        }
        return predicate
    }
}
