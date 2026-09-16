import Foundation
import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Filter.Detail.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminder.Filter.Detail? {
        guard let filter else { return nil }
        let preference = try Reminder.Filter.Preference.Record.preference(for: filter).fetchOne(db).map(Reminder.Filter.Preference.init) ?? filter.defaultPreference
        var list: List<Reminder>?
        if case let .list(id) = filter {
            list = try List<Reminder>.Record.find(id).fetchOne(db).map(List<Reminder>.init)
        }
        let shown = Reminder.Record
            .where { $0.belongs(to: filter, today: today) }
            .where { if !preference.showCompleted { !$0.isDone } }
        let total = try shown.fetchCount(db)
        let completedCount = preference.showCompleted ? try shown.where { $0.isDone }.fetchCount(db) : 0
        let rows = try shown
            .order { $0.ordered(by: preference.ordering, showCompleted: preference.showCompleted, placing: place) }
            .limit(limit ?? total)
            .rows()
            .fetchAll(db)
        return Reminder.Filter.Detail(
            filter: filter,
            color: list?.color,
            preference: preference,
            rows: rows.map { Reminder.Filter.Detail.Row(reminder: Reminder($0), color: Color($0.color)) },
            total: total,
            completedCount: completedCount
        )
    }
}
