public import Dependencies
import Reminder
public import Reminders
public import Reminders_Dependency
public import Reminders_Session
import Reminders_SQL
public import SQLiteData

extension Reminders.Session.Client {
    public static func sqlite(_ database: any DatabaseWriter) -> Reminders.Session.Client {
        Reminders.Session.Client(
            current: {
                try database.read { db in
                    guard let record = try Reminders.Session.Record.current.fetchOne(db) else { return Reminders.Session() }
                    let editing = try record.editing.flatMap { try Reminder.Record.find($0).rows().fetchOne(db) }.map(Reminders.Placement.init)
                    return Reminders.Session(record, editing: editing)
                }
            },
            setFilter: { filter in try database.write { db in try Reminders.Session.Record.set(filter: filter).execute(db) } },
            setEditing: { id in try database.write { db in try Reminders.Session.Record.set(editing: id).execute(db) } }
        )
    }
}

extension Reminders.Session.Client: DependencyKey {
    public static var liveValue: Reminders.Session.Client {
        @Dependency(\.defaultDatabase) var database
        return .sqlite(database)
    }
}
