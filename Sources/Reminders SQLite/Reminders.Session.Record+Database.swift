public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminders.Session.Record {
    public static func install(in db: Database) throws {
        let install = Reminders.Session.Record.insert { Reminders.Session.Record() } onConflict: { $0.id }
        try install.execute(db)
    }
}
