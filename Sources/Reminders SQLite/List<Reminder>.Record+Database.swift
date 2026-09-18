public import Foundation
public import Models
public import Reminder
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Models.List<Reminder>.Record {
    public static func installDefault(_ id: @autoclosure () -> Models.List<Reminder>.ID, in db: Database) throws {
        guard try Models.List<Reminder>.Record.where { $0.deleted.is(nil) }.fetchCount(db) == 0 else { return }
        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(.default(id: id())) }.execute(db)
    }

    // A deleted list and its reminders wait in Recently Deleted together.
    public static func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID, at now: Date, in db: Database) throws {
        try Models.List<Reminder>.Record.find(id).update { $0.deleted = #bind(now) }.execute(db)
        try Reminder.Record.where { $0.listID.eq(id) && $0.isKept }.update { $0.deleted = #bind(now) }.execute(db)
        try installDefault(replacement, in: db)
    }
}
