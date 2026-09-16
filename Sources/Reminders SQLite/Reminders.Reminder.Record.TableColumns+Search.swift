import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders.Reminder.Record.TableColumns {
    func matches(_ text: String) -> some QueryExpression<Bool> {
        let folded = searchFolded(text)
        return #sql("instr(\"reminders\".\"searchText\", \(bind: folded)) > 0", as: Bool.self)
            || Reminders.Tagging
                .where { $0.reminderID.eq(id) && $0.tagID.text.in(Tag<Reminder>.Record.where { $localizedCaseInsensitiveContains($0.title, text) }.select(\.title)) }
                .exists()
    }

    public func matches(_ search: Reminders.Search) -> SQLQueryExpression<Bool> {
        guard search.matchesReminders else { return SQLQueryExpression("0") }
        var predicate = SQLQueryExpression<Bool>(search.matchedText.isEmpty ? "1" : "(\(matches(search.matchedText)))")
        for token in search.tokens {
            switch token {
            case let .near(text): predicate = SQLQueryExpression("\(predicate) AND (\(matches(text)))")
            case let .tag(tag): predicate = SQLQueryExpression("\(predicate) AND (\(carries(tag)))")
            }
        }
        return predicate
    }
}
