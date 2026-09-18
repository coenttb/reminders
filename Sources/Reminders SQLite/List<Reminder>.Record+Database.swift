import Dependencies
public import Models
public import Reminder
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Models.List<Reminder>.Record {
    // There is always a list to put a reminder in; its identity is storage's to mint.
    public static func installDefault(in db: Database) throws {
        guard try Models.List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        @Dependency(\.uuid) var uuid
        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(.default(id: Models.List<Reminder>.ID(uuid()))) }.execute(db)
    }
}
