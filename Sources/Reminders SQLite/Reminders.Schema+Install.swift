public import Models
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Schema {
    public static func install(_ db: Database, default id: @autoclosure () -> Models.List<Reminder>.ID) throws {
        try Models.List<Reminder>.Record.installDefault(id(), in: db)
    }
}
