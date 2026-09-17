import Foundation
import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.TableColumns {
    func matches(_ text: String) -> some QueryExpression<Bool> {
        let folded = Reminders.Schema.searchFolded(text)
        return #sql("instr(\"reminders\".\"searchText\", \(bind: folded)) > 0", as: Bool.self)
            || Reminders.Tagging
                .where { $0.reminderID.eq(id) && $0.tagID.text.in(Tag<Reminder>.Record.where { Reminders.Schema.$localizedCaseInsensitiveContains($0.title, text) }.select(\.title)) }
                .exists()
    }

    public func matches(_ query: Reminders.Query) -> SQLQueryExpression<Bool> {
        var predicate = SQLQueryExpression<Bool>("1")
        for term in query.terms {
            predicate = SQLQueryExpression("\(predicate) AND (\(matches(term)))")
        }
        for tag in query.tags.sorted() {
            predicate = SQLQueryExpression("\(predicate) AND (\(Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()))")
        }
        return predicate
    }
}
