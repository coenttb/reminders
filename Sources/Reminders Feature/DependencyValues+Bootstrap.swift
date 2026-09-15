public import Dependencies
import Reminders
import Reminders_SQLiteData
import SQLiteData
#if canImport(os)
import os
#endif

extension DependencyValues {
    /// Opens the application's default database, creates the Reminders schema, and makes it
    /// the feature's database. In Debug every statement is traced, to the log while live and
    /// to the console in a preview, so the cost of a write can be measured rather than assumed.
    public mutating func bootstrapDatabase() throws {
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
        let database = try SQLiteData.defaultDatabase(configuration: configuration)
        try Lists.migrate(database)
        defaultDatabase = database
    }
}

#if canImport(os)
private let logger = Logger(subsystem: "com.coenttb.apple-apps.reminders", category: "Database")
#endif
