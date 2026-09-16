public import Models
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Schema {
    public static func install(_ db: Database, default id: @autoclosure () -> List<Reminder>.ID) throws {
        try Reminders.Session.Record.install(in: db)
        try List<Reminder>.Record.installDefault(id(), in: db)
    }
}
