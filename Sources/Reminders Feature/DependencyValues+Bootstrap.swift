public import Dependencies
import Reminders
import Reminders_SQLiteData
import SQLiteData

extension DependencyValues {
    /// Opens the application's default database, creates the Reminders schema, and makes it the feature's database.
    public mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()
        try Lists.migrate(database)
        defaultDatabase = database
    }
}
