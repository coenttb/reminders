import Foundation
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.TableColumns {
    fileprivate func placed<Value: _OptionalPromotable>(
        _ column: some QueryExpression<Value>,
        _ value: some QueryExpression<Value>,
        of place: Reminders.Placement?
    ) -> SQLQueryExpression<Value> {
        guard let place else { return SQLQueryExpression("\(column)") }
        return SQLQueryExpression("\(Case().when(id.eq(place.reminder.id), then: value).else(column))")
    }

    public func ordered(by preference: Reminders.Preference, placing place: Reminders.Placement? = nil) -> SQLQueryExpression<Bool> {
        let dueDate = placed(dueDate, place?.reminder.due?.date, of: place)
        let position = placed(position, place?.position ?? 0, of: place)
        let priority = placed(priority, place?.reminder.priority, of: place)
        let flagged = placed(flagged, place?.reminder.flagged ?? false, of: place)
        let title = placed(title, place?.reminder.title ?? "", of: place)
        let created = placed(created, place?.reminder.created ?? .distantPast, of: place)
        let completed = placed(isCompleted, place?.reminder.completed ?? false, of: place)
        var fragment: QueryFragment = preference.showCompleted ? "\(completed), " : ""
        // A reversed direction turns the key around; rows without a date or priority stay last either way.
        let forward = preference.direction == .forward
        switch preference.ordering {
        case .dueDate: fragment.append("\(forward ? dueDate.asc(nulls: .last) : dueDate.desc(nulls: .last)), \(position)")
        case .creationDate: fragment.append("\(forward ? created.asc() : created.desc()), \(position)")
        case .manual: fragment.append("\(position)")
        case .priority: fragment.append("\(forward ? priority.desc(nulls: .last) : priority.asc(nulls: .last)), \(forward ? flagged.desc() : flagged.asc()), \(position)")
        case .title:
            let title = title.collate(Reminders.Schema.$localizedCaseInsensitive)
            fragment.append("\(forward ? title.asc() : title.desc()), \(position)")
        }
        return SQLQueryExpression(fragment)
    }
}
