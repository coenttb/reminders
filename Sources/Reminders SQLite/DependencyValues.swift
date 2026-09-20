public import Dependencies
import List
import Reminder
public import Reminders
import Reminders_Dependency
public import Reminders_Sample
import Reminders_SQL
import SQLiteData
import Tagged

extension DependencyValues {
    // The one place the app opens its database and binds the domain to it.
    public mutating func bootstrapDatabase(seeding sample: Reminders.Sample? = nil) throws {
        let database = try Reminders.database()
        try database.write { db in
            try sample?.initialize(in: db)
            try List<Reminder>.Record.installDefault(in: db)
        }
        defaultDatabase = database
        reminders = .sqlite(database)
    }
}
