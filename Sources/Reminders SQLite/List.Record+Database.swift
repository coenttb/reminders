public import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension List<Reminder>.Record {
    public static func delete(_ id: List<Reminder>.ID, replacement: List<Reminder>.ID, in db: Database) throws {
        try List<Reminder>.Record.find(id).delete().execute(db)
        if try List<Reminder>.Record.all.fetchCount(db) == 0 {
            try List<Reminder>.Record.insert { List<Reminder>.Record(.default(id: replacement)) }.execute(db)
        }
    }
}
