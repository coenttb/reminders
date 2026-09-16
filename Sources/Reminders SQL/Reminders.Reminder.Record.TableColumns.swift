public import Foundation
public import Organizing
public import Reminders
public import StructuredQueries
public import Tagged

extension Reminders.Reminder.Record.TableColumns {
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
        case let .tags(tags): SQLQueryExpression("\(Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(Array(tags)) }.exists())")
        case .today: SQLQueryExpression("\(isDue(during: today))")
        }
    }

    package func carries(_ tag: Tag<Reminder>.ID) -> some QueryExpression<Bool> {
        Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(tag) }.exists()
    }

    public var tagList: some QueryExpression<String?> {
        Reminders.Tagging
            .where { $0.reminderID.eq(id) }
            .join(Tag<Reminder>.Record.all) { $1.title.eq($0.tagID.text) }
            .select { $1.title.groupConcat(Reminder.Record.tagSeparator, order: $1.title) }
    }
}
