public import Dependencies
import Organizing
public import Reminders
public import Reminders_Sample
import Reminders_SQL
import SQLiteData
import Tagged
#if canImport(os)
import os
#endif

extension DependencyValues {
    /// Opens the app's database, migrates it, and puts the baseline in place; a sample, when given,
    /// is written first into a database that is still empty.
    public mutating func bootstrapDatabase(seeding sample: Reminders.Sample? = nil) throws {
        var configuration = Configuration()
        #if DEBUG
        let context = self.context
        configuration.prepareDatabase { db in
            db.trace(options: .profile) { event in
                guard !event.expandedDescription.hasPrefix("--") else { return }
                switch context {
                case .live:
                    #if canImport(os)
                    logger.debug("\(event.expandedDescription)")
                    #endif
                case .preview:
                    print(event.expandedDescription)
                case .test:
                    break
                }
            }
        }
        #endif
        let database = try Reminders.Schema.database(configuration)
        try database.write { db in
            try sample?.initialize(in: db)
            try Reminders.Schema.install(db, default: List<Reminder>.ID(uuid()))
        }
        defaultDatabase = database
    }
}

#if canImport(os)
private let logger = Logger(subsystem: "com.coenttb.reminders", category: "Database")
#endif
