public import Models
public import Reminder
public import Reminders
public import Reminders_Sample
import Reminders_SQL
public import SQLiteData

extension Reminders.Sample {
    public func initialize(in db: Database) throws {
        guard try Models.List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        try Models.List<Reminder>.Record.insert { lists.enumerated().map { Models.List<Reminder>.Record($1, position: $0) } }.execute(db)
        try Reminder.Record.insert { reminders.enumerated().map { Reminder.Record.Draft($1, position: $0) } }.execute(db)
    }
}
