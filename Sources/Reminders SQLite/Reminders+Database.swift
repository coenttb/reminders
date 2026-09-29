public import GRDB
public import Reminders
import SQL
import SQL_Macros
import SQLite

extension Reminders {
    public static func migrate(_ database: some DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true
        migrator.registerMigration("Create the Reminders tables") { db in
            try #sql("""
                CREATE TABLE "lists" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "reminders" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "completed" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0 CHECK ("completed" IN (0, 1)),
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "created" TEXT NOT NULL
                ) STRICT
                """).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
        }
        try migrator.migrate(database)
    }
}
