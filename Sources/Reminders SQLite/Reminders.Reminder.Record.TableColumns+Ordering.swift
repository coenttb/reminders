import Foundation
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminders.Reminder.Record.TableColumns {
    fileprivate func placed<Value: _OptionalPromotable>(
        _ column: some QueryExpression<Value>,
        _ value: some QueryExpression<Value>,
        of place: Reminder?
    ) -> SQLQueryExpression<Value> {
        guard let place else { return SQLQueryExpression("\(column)") }
        return SQLQueryExpression("\(Case().when(id.eq(place.id), then: value).else(column))")
    }

    public func ordered(by ordering: Reminders.Ordering, showCompleted: Bool, placing place: Reminder? = nil) -> SQLQueryExpression<Bool> {
        let dueDate = placed(dueDate, place?.due?.date, of: place)
        let position = placed(position, place?.position ?? 0, of: place)
        let priority = placed(priority, place?.priority, of: place)
        let flagged = placed(flagged, place?.flagged ?? false, of: place)
        let title = placed(title, place?.title ?? "", of: place)
        let created = placed(created, place?.created ?? .distantPast, of: place)
        let completed = placed(isCompleted, place?.completed ?? false, of: place)
        var fragment: QueryFragment = showCompleted ? "\(completed), " : ""
        switch ordering {
        case .dueDate: fragment.append("\(dueDate.asc(nulls: .last)), \(position)")
        case .creationDate: fragment.append("\(created), \(position)")
        case .manual: fragment.append("\(position)")
        case .priority: fragment.append("\(priority.desc(nulls: .last)), \(flagged.desc()), \(position)")
        case .title: fragment.append("\(title.collate(Reminders.Schema.$localizedCaseInsensitive)), \(position)")
        }
        return SQLQueryExpression(fragment)
    }
}
