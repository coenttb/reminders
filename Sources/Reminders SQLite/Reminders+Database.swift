public import Reminders
public import SQLiteData

extension Reminders {
    public static func migrate(_ database: some DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Create the Reminders tables") { db in
            try #sql("""
                CREATE TABLE "lists" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "reminders" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "completed" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0 CHECK ("completed" IN (0, 1)),
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000'
                ) STRICT
                """).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
        }
        try migrator.migrate(database)
    }

    public static func database(_ configuration: Configuration = Configuration()) throws -> any DatabaseWriter {
        var configuration = configuration
        configuration.foreignKeysEnabled = true
        let database = try SQLiteData.defaultDatabase(configuration: configuration)
        try migrate(database)
        return database
    }
}
