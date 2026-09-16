public import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension List<Reminder>.Record {
    public static func installDefault(_ id: @autoclosure () -> List<Reminder>.ID, in db: Database) throws {
        guard try List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        try List<Reminder>.Record.insert { List<Reminder>.Record(.default(id: id())) }.execute(db)
    }

    public static func delete(_ id: List<Reminder>.ID, replacement: List<Reminder>.ID, in db: Database) throws {
        try List<Reminder>.Record.find(id).delete().execute(db)
        try installDefault(replacement, in: db)
    }
}
