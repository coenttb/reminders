public import Foundation
public import Reminders
public import SQLiteData
import Tagged

extension Reminder.Record.TableColumns {
    /// Completing counts as completed everywhere but the grace timer.
    public var isCompleted: some QueryExpression<Bool> {
        status.neq(Reminder.Status.incomplete.rawValue)
    }

    public var isCompleting: some QueryExpression<Bool> {
        status.eq(Reminder.Status.completing.rawValue)
    }

    /// Fully completed: the grace period is over.
    public var isDone: some QueryExpression<Bool> {
        status.eq(Reminder.Status.completed.rawValue)
    }

    public var isScheduled: some QueryExpression<Bool> {
        !isCompleted && due.isNot(nil)
    }

    /// Incomplete and due within a day's bounds; the bounds come from the app's calendar, so
    /// the database has no say in where a day starts.
    public func isDue(during day: Range<Date>) -> some QueryExpression<Bool> {
        !isCompleted && #sql("coalesce(\(due) >= \(day.lowerBound) AND \(due) < \(day.upperBound), 0)")
    }

    /// Whether the reminder belongs to a detail; `today` is the day the detail of that name shows.
    public func belongs(to detail: Lists.Detail, today: Range<Date>) -> SQLQueryExpression<Bool> {
        switch detail {
        case .all: SQLQueryExpression("1")
        case .completed: SQLQueryExpression("\(isCompleted)")
        case .flagged: SQLQueryExpression("\(flagged)")
        case let .list(id): SQLQueryExpression("\(listID.eq(id))")
        case .scheduled: SQLQueryExpression("\(isScheduled)")
        case let .tags(tags): SQLQueryExpression("\(Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.exists())")
        case .today: SQLQueryExpression("\(isDue(during: today))")
        }
    }

    /// Whether the title, notes, or a tag contains the text, case-insensitively as Swift compares.
    fileprivate func matches(_ text: String) -> some QueryExpression<Bool> {
        $localizedCaseInsensitiveContains(title, text)
            || $localizedCaseInsensitiveContains(notes, text)
            || Reminder.Tagging.where { $0.reminderID.eq(id) && $localizedCaseInsensitiveContains($0.tagID.text, text) }.exists()
    }

    /// Whether the reminder carries the tag.
    fileprivate func carries(_ tag: Tag.ID) -> some QueryExpression<Bool> {
        Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()
    }

    /// Whether the reminder matches every term of a search; a search that names no reminders
    /// (nothing typed, or a tag prefix alone) matches none.
    public func matches(_ search: Lists.Search) -> SQLQueryExpression<Bool> {
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

    /// The tags the reminder carries, joined by the unit separator, in tag order; the titles are
    /// read from the tags table, so the case the tag is stored in is what a reminder shows.
    public var tagList: some QueryExpression<String?> {
        Reminder.Tagging
            .where { $0.reminderID.eq(id) }
            .join(Tag.Record.all) { $0.tagID.text.eq($1.title) }
            .select { $1.title.groupConcat(Reminder.Record.tagSeparator, order: $1.title) }
    }
}

extension Reminder.Record {
    static let tagSeparator = "\u{1F}"

    static func tags(from list: String?) -> Set<Tag.ID> {
        Set((list ?? "").split(separator: tagSeparator).map { Tag.ID(String($0)) })
    }
}

extension Reminder.Record.TableColumns {
    /// The value a column sorts by: the reminder's own, or the place's for the row being edited,
    /// so that row keeps the place it had when editing began.
    fileprivate func placed<Value>(
        _ column: some QueryExpression<Value>,
        _ value: some QueryExpression<Value>,
        of place: Reminder?
    ) -> SQLQueryExpression<Value> {
        guard let place else { return SQLQueryExpression("\(column)") }
        return #sql("CASE WHEN \(id) = \(place.id) THEN \(value) ELSE \(column) END")
    }

    /// The ordering a preference asks for, ties broken by position as the manual order has it.
    /// Completed reminders sort last only when the detail shows them; one in its grace period
    /// keeps its place, so the tap can be undone.
    public func ordered(by ordering: Lists.Ordering, showCompleted: Bool, placing place: Reminder? = nil) -> SQLQueryExpression<Bool> {
        let due = placed(due, place?.due, of: place)
        let position = placed(position, place?.position ?? 0, of: place)
        let priority = placed(priority, place?.priority?.rawValue, of: place)
        let flagged = placed(flagged, place?.flagged ?? false, of: place)
        let title = placed(title, place?.title ?? "", of: place)
        let completed = placed(isCompleted, place?.completed ?? false, of: place)
        var fragment: QueryFragment = showCompleted ? "\(completed), " : ""
        switch ordering {
        case .dueDate: fragment.append("\(due.asc(nulls: .last)), \(position)")
        case .manual: fragment.append("\(position)")
        case .priority: fragment.append("\(priority.ifnull(0).desc()), \(flagged.desc()), \(position)")
        case .title: fragment.append("\(title.collate($localizedCaseInsensitive)), \(position)")
        }
        return SQLQueryExpression(fragment)
    }
}

extension QueryExpression where QueryValue == Tag.ID {
    /// The tag's title as the text column it is stored in.
    var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
