public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminders.Restoration {
    public static func install(in db: Database) throws {
        let install = Reminders.Restoration.insert { Reminders.Restoration() } onConflict: { $0.id }
        try install.execute(db)
    }
}
