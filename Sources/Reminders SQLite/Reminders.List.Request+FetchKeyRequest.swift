import Models
import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders.List.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.List.Result {
        let preference: Reminders.Preference = switch selection {
        case let .filter(filter):
            try Reminders.Preference.Record.preference(for: filter).fetchOne(db).map(Reminders.Preference.init) ?? .default(for: filter)
        case let .search(query):
            Reminders.Preference(ordering: .dueDate, showCompleted: query.showCompleted)
        }
        let matching = Reminder.Record.where { $0.selected(by: selection, today: today) }
        let shown = matching.where { if !preference.showCompleted { !$0.isCompleted } }
        let total = try shown.fetchCount(db)
        let completed = try matching.where { $0.isCompleted }.fetchCount(db)
        let rows: [Reminder] = switch selection {
        case .filter:
            try shown
                .order { $0.ordered(by: preference.ordering, showCompleted: preference.showCompleted, placing: including) }
                .limit(limit ?? total)
                .rows()
                .fetchAll(db)
                .map(Reminder.init)
        case .search:
            try shown
                .join(Models.List<Reminder>.Record.all) { $0.listID.eq($1.id) }
                .order { reminders, lists in
                    (lists.position, reminders.isCompleted, reminders.ordered(by: .dueDate, showCompleted: false))
                }
                .limit(limit ?? total)
                .select { reminders, _ in Reminder.Record.Row.Columns(reminder: reminders, tags: reminders.tagTitles) }
                .fetchAll(db)
                .map(Reminder.init)
        }
        return Reminders.List.Result(selection: selection, preference: preference, rows: rows, total: total, completed: completed)
    }
}
