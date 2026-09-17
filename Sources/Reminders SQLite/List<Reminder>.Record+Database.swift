public import Models
public import Reminder
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Models.List<Reminder>.Record {
    public static func installDefault(_ id: @autoclosure () -> Models.List<Reminder>.ID, in db: Database) throws {
        guard try Models.List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(.default(id: id())) }.execute(db)
    }

    public static func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID, in db: Database) throws {
        try Models.List<Reminder>.Record.find(id).delete().execute(db)
        try installDefault(replacement, in: db)
    }
}
