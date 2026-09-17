import Foundation
import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.TableColumns {
    // A term matches at the start of a word in the title, the notes, or a tag; the words of a term
    // are a phrase. The user's text is quoted so it can never be read as query syntax.
    func matches(_ term: String) -> some QueryExpression<Bool> {
        let words = term.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let phrase = "\"" + words.replacingOccurrences(of: "\"", with: "\"\"") + "\"*"
        return rowid.in(Reminder.Record.Text.where { $0.match(phrase) }.select(\.rowid))
    }

    public func matches(_ query: Reminders.Query) -> SQLQueryExpression<Bool> {
        var predicate = SQLQueryExpression<Bool>("1")
        for term in query.terms where !term.trimmingCharacters(in: .whitespaces).isEmpty {
            predicate = SQLQueryExpression("\(predicate) AND (\(matches(term)))")
        }
        for tag in query.tags.sorted() {
            predicate = SQLQueryExpression("\(predicate) AND (\(Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()))")
        }
        return predicate
    }
}
