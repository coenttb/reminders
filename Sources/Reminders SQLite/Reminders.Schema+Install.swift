public import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Schema {
    /// What every database holds before anything is written: the restoration row and one list.
    /// The id is minted only when a list is needed.
    public static func install(_ db: Database, default id: @autoclosure () -> List<Reminder>.ID) throws {
        try Reminders.Restoration.install(in: db)
        try List<Reminder>.Record.installDefault(id(), in: db)
    }
}
