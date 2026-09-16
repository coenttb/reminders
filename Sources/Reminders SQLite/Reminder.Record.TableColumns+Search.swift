import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminder.Record.TableColumns {
    func matches(_ text: String) -> some QueryExpression<Bool> {
        let folded = Reminders.Schema.searchFolded(text)
        return #sql("instr(\"reminders\".\"searchText\", \(bind: folded)) > 0", as: Bool.self)
            || Reminders.Tagging
                .where { $0.reminderID.eq(id) && $0.tagID.text.in(Tag<Reminder>.Record.where { Reminders.Schema.$localizedCaseInsensitiveContains($0.title, text) }.select(\.title)) }
                .exists()
    }

    public func matches(_ query: Reminders.Search.Query) -> SQLQueryExpression<Bool> {
        guard query.matchesReminders else { return SQLQueryExpression("0") }
        var predicate = SQLQueryExpression<Bool>(query.matchedText.isEmpty ? "1" : "(\(matches(query.matchedText)))")
        for token in query.tokens {
            switch token {
            case let .near(text): predicate = SQLQueryExpression("\(predicate) AND (\(matches(text)))")
            case let .tag(tag): predicate = SQLQueryExpression("\(predicate) AND (\(carries(tag)))")
            }
        }
        return predicate
    }
}
