import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders.Filter.Detail.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Filter.Detail.Contents? {
        guard let filter else { return nil }
        let preference = try Reminders.Filter.Preference.Record.preference(for: filter).fetchOne(db).map(Reminders.Filter.Preference.init) ?? .default(for: filter)
        let shown = Reminder.Record
            .where { $0.belongs(to: filter, today: today) }
            .where { if !preference.showCompleted { !$0.isCompleted } }
        let total = try shown.fetchCount(db)
        let completedCount = preference.showCompleted ? try shown.where { $0.isCompleted }.fetchCount(db) : 0
        let rows = try shown
            .order { $0.ordered(by: preference.ordering, showCompleted: preference.showCompleted, placing: place) }
            .limit(limit ?? total)
            .rows()
            .fetchAll(db)
            .map(Reminder.init)
        return Reminders.Filter.Detail.Contents(
            filter: filter,
            preference: preference,
            rows: rows,
            total: total,
            completedCount: completedCount
        )
    }
}
