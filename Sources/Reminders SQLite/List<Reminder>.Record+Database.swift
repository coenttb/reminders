public import Models
public import Reminder
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Models.List<Reminder>.Record {
    // There is always a list to put a reminder in.
    public static func installDefault(_ id: @autoclosure () -> Models.List<Reminder>.ID, in db: Database) throws {
        guard try Models.List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(.default(id: id())) }.execute(db)
    }
}
