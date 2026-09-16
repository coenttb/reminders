import Foundation
import Organizing
public import Reminders
import Reminders_Interface
import Reminders_Sample
public import SQLiteData

extension Reminder {
    public enum Schema {}
}

extension Reminder.Schema {
    public static func migrate(_ database: some DatabaseWriter, upTo target: String? = nil) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create the Reminders tables") { db in
            try #sql("""
                CREATE TABLE "lists" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "color" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "reminders" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "notes" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "due" TEXT,
                  "hasTime" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "flagged" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "priority" INTEGER,
                  "status" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "location" TEXT,
                  "repeats" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'never'
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "tags" (
                  "title" TEXT COLLATE NOCASE PRIMARY KEY NOT NULL
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "remindersTags" (
                  "reminderID" TEXT NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
                  "tagID" TEXT NOT NULL REFERENCES "tags"("title") ON DELETE CASCADE ON UPDATE CASCADE,
                  PRIMARY KEY ("reminderID", "tagID")
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "preferences" (
                  "key" TEXT PRIMARY KEY NOT NULL,
                  "ordering" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "showCompleted" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "session" (
                  "id" INTEGER PRIMARY KEY NOT NULL,
                  "filter" TEXT,
                  "editing" TEXT
                ) STRICT
                """).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_reminderID" ON "remindersTags"("reminderID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_tagID" ON "remindersTags"("tagID")"#).execute(db)
        }
        migrator.registerMigration("Compare tag titles as Swift does") { db in
            try #sql("""
                CREATE TABLE "tags_new" (
                  "title" TEXT COLLATE "localizedCaseInsensitive" PRIMARY KEY NOT NULL
                ) STRICT
                """).execute(db)
            try #sql(#"INSERT OR IGNORE INTO "tags_new" SELECT "title" FROM "tags" ORDER BY "rowid""#).execute(db)
            try #sql("""
                CREATE TABLE "remindersTags_new" (
                  "reminderID" TEXT NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
                  "tagID" TEXT NOT NULL REFERENCES "tags"("title") ON DELETE CASCADE ON UPDATE CASCADE,
                  PRIMARY KEY ("reminderID", "tagID")
                ) STRICT
                """).execute(db)
            try #sql("""
                INSERT OR IGNORE INTO "remindersTags_new"
                SELECT "reminderID", (SELECT "tags_new"."title" FROM "tags_new" WHERE "tags_new"."title" = "remindersTags"."tagID")
                FROM "remindersTags" ORDER BY "rowid"
                """).execute(db)
            try #sql(#"DROP TABLE "remindersTags""#).execute(db)
            try #sql(#"DROP TABLE "tags""#).execute(db)
            try #sql(#"ALTER TABLE "tags_new" RENAME TO "tags""#).execute(db)
            try #sql(#"ALTER TABLE "remindersTags_new" RENAME TO "remindersTags""#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_reminderID" ON "remindersTags"("reminderID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_tagID" ON "remindersTags"("tagID")"#).execute(db)
        }
        migrator.registerMigration("Constrain what a reminder row may hold") { db in
            try #sql("""
                CREATE TABLE "reminders_new" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "notes" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "due" TEXT CHECK ("due" IS NULL OR "due" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "hasTime" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "flagged" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "priority" INTEGER CHECK ("priority" IS NULL OR "priority" IN (1, 2, 3)),
                  "status" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0 CHECK ("status" IN (0, 1, 2)),
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "location" TEXT,
                  "repeats" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'never'
                ) STRICT
                """).execute(db)
            try #sql("""
                INSERT INTO "reminders_new"
                SELECT "id", "listID", "title", "notes",
                  CASE WHEN "due" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]' THEN "due" ELSE NULL END,
                  "hasTime", "flagged",
                  CASE WHEN "priority" IN (1, 2, 3) THEN "priority" ELSE NULL END,
                  CASE WHEN "status" IN (0, 1, 2) THEN "status" ELSE 0 END,
                  "position", "location", "repeats"
                FROM "reminders" ORDER BY "rowid"
                """).execute(db)
            try #sql(#"DROP TABLE "reminders""#).execute(db)
            try #sql(#"ALTER TABLE "reminders_new" RENAME TO "reminders""#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
        }
        migrator.registerMigration("Record when a reminder was created") { db in
            try #sql(#"ALTER TABLE "reminders" ADD COLUMN "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]')"#).execute(db)
        }
        migrator.registerMigration("Index the due date and the status") { db in
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_status" ON "reminders"("status")"#).execute(db)
        }
        migrator.registerMigration("Keep the folded text for the search") { db in
            try #sql(#"ALTER TABLE "reminders" ADD COLUMN "searchText" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''"#).execute(db)
            try #sql(#"UPDATE "reminders" SET "searchText" = searchFolded("title" || char(10) || "notes")"#).execute(db)
            try #sql(#"""
                CREATE TRIGGER "reminders_searchText_insert" AFTER INSERT ON "reminders" BEGIN
                  UPDATE "reminders" SET "searchText" = searchFolded(NEW."title" || char(10) || NEW."notes") WHERE "id" = NEW."id";
                END
                """#).execute(db)
            try #sql(#"""
                CREATE TRIGGER "reminders_searchText_update" AFTER UPDATE OF "title", "notes" ON "reminders" BEGIN
                  UPDATE "reminders" SET "searchText" = searchFolded(NEW."title" || char(10) || NEW."notes") WHERE "id" = NEW."id";
                END
                """#).execute(db)
        }
        if let target {
            try migrator.migrate(database, upTo: target)
        } else {
            try migrator.migrate(database)
        }
    }

    public static func prepare(_ configuration: inout Configuration) {
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            db.add(function: $localizedCaseInsensitiveContains)
            db.add(function: $hasCaseInsensitivePrefix)
            db.add(function: $searchFolded)
            db.add(collation: $localizedCaseInsensitive)
            db.add(collation: .canonical)
        }
    }

    public static func inMemoryDatabase() throws -> DatabaseQueue {
        var configuration = Configuration()
        prepare(&configuration)
        let database = try DatabaseQueue(configuration: configuration)
        try migrate(database)
        return database
    }
}
