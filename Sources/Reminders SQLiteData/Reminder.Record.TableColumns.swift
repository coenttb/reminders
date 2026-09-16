public import Foundation
import Organizing
public import Reminders
public import Reminders_Interface
public import SQLiteData
import Standard_Library_Extensions
import Tagged

extension Reminder.Record.TableColumns {
    public var isCompleted: some QueryExpression<Bool> {
        status.neq(Reminder.Record.incomplete)
    }

    public var isPending: some QueryExpression<Bool> {
        status.eq(Reminder.Record.pending)
    }

    public var isDone: some QueryExpression<Bool> {
        status.eq(Reminder.Record.completed)
    }

    public var isScheduled: some QueryExpression<Bool> {
        !isCompleted && due.isNot(nil)
    }

    public func isDue(during day: Range<Date>) -> some QueryExpression<Bool> {
        !isCompleted && due.isNot(nil) && due.gte(Date?.some(day.lowerBound)) && due.lt(Date?.some(day.upperBound))
    }

    public func belongs(to filter: Reminders.Filter, today: Range<Date>) -> SQLQueryExpression<Bool> {
        switch filter {
        case .all: SQLQueryExpression("1")
        case .completed: SQLQueryExpression("\(isCompleted)")
        case .flagged: SQLQueryExpression("\(flagged)")
        case let .list(id): SQLQueryExpression("\(listID.eq(id))")
        case .scheduled: SQLQueryExpression("\(isScheduled)")
        case let .tags(tags): SQLQueryExpression("\(Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.exists())")
        case .today: SQLQueryExpression("\(isDue(during: today))")
        }
    }

    fileprivate func matches(_ text: String) -> some QueryExpression<Bool> {
        let folded = searchFolded(text)
        return #sql("instr(\"reminders\".\"searchText\", \(bind: folded)) > 0", as: Bool.self)
            || Reminder.Tagging
                .where { $0.reminderID.eq(id) && $0.tagID.text.in(Tag<Reminder>.Record.where { $localizedCaseInsensitiveContains($0.title, text) }.select(\.title)) }
                .exists()
    }

    fileprivate func carries(_ tag: Tag<Reminder>.ID) -> some QueryExpression<Bool> {
        Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()
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

    public var tagList: some QueryExpression<String?> {
        Reminder.Tagging
            .where { $0.reminderID.eq(id) }
            .join(Tag<Reminder>.Record.all) { $1.title.eq($0.tagID.text) }
            .select { $1.title.groupConcat(Reminder.Record.tagSeparator, order: $1.title) }
    }
}

extension Reminder.Record.TableColumns {
    fileprivate func placed<Value: _OptionalPromotable>(
        _ column: some QueryExpression<Value>,
        _ value: some QueryExpression<Value>,
        of place: Reminder?
    ) -> SQLQueryExpression<Value> {
        guard let place else { return SQLQueryExpression("\(column)") }
        return SQLQueryExpression("\(Case().when(id.eq(place.id), then: value).else(column))")
    }

    public func ordered(by ordering: Reminders.Ordering, showCompleted: Bool, placing place: Reminder? = nil) -> SQLQueryExpression<Bool> {
        let due = placed(due, place?.due?.date, of: place)
        let position = placed(position, place?.position ?? 0, of: place)
        let priority = placed(priority, place?.priority?.rawValue, of: place)
        let flagged = placed(flagged, place?.flagged ?? false, of: place)
        let title = placed(title, place?.title ?? "", of: place)
        let created = placed(created, place?.created ?? .distantPast, of: place)
        let completed = placed(isCompleted, place?.completed ?? false, of: place)
        var fragment: QueryFragment = showCompleted ? "\(completed), " : ""
        switch ordering {
        case .dueDate: fragment.append("\(due.asc(nulls: .last)), \(position)")
        case .creationDate: fragment.append("\(created), \(position)")
        case .manual: fragment.append("\(position)")
        case .priority: fragment.append("\(priority.ifnull(0).desc()), \(flagged.desc()), \(position)")
        case .title: fragment.append("\(title.collate($localizedCaseInsensitive)), \(position)")
        }
        return SQLQueryExpression(fragment)
    }
}
