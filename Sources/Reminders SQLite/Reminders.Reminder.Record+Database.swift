public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Reminder.Record {
    public static func reorder(_ ids: [Reminder.ID], in db: Database) throws {
        let stored = Dictionary(uniqueKeysWithValues: try Reminder.Record.where { $0.id.in(ids) }.select { ($0.id, $0.position) }.fetchAll(db))
        let ordered = ids.filter { stored[$0] != nil }
        let positions = ordered.compactMap { stored[$0] }.sorted()
        for (id, position) in zip(ordered, positions) where stored[id] != position {
            try Reminder.Record.find(id).update { $0.position = position }.execute(db)
        }
    }
}
