public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders {
    public enum Schema {}
}

extension Reminders.Schema {
    public static func migrate(_ database: some DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create the Reminders tables") { db in
            try #sql("""
                CREATE TABLE "lists" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "color" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "reminders" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "notes" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "due" TEXT CHECK ("due" IS NULL OR "due" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "hasTime" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "flagged" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "priority" INTEGER CHECK ("priority" IS NULL OR "priority" IN (1, 2, 3)),
                  "completed" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0 CHECK ("completed" IN (0, 1)),
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "repeats" TEXT CHECK ("repeats" IS NULL OR json_valid("repeats")),
                  "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]')
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "tags" (
                  "title" TEXT COLLATE "localizedCaseInsensitive" PRIMARY KEY NOT NULL
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
                  "direction" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'forward' CHECK ("direction" IN ('forward', 'reverse')),
                  "showCompleted" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_completed" ON "reminders"("completed")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_reminderID" ON "remindersTags"("reminderID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_tagID" ON "remindersTags"("tagID")"#).execute(db)
            // The full-text index of the title, the notes, and the tag titles, kept in step by triggers
            // and addressed by the reminder's rowid.
            try #sql("""
                CREATE VIRTUAL TABLE "reminderTexts" USING fts5(
                  "title",
                  "notes",
                  "tags",
                  tokenize = 'unicode61 remove_diacritics 2'
                )
                """).execute(db)
            try #sql(#"""
                CREATE TRIGGER "reminders_text_insert" AFTER INSERT ON "reminders" BEGIN
                  INSERT INTO "reminderTexts" ("rowid", "title", "notes", "tags") VALUES (NEW."rowid", NEW."title", NEW."notes", '');
                END
                """#).execute(db)
            try #sql(#"""
                CREATE TRIGGER "reminders_text_update" AFTER UPDATE OF "title", "notes" ON "reminders" BEGIN
                  UPDATE "reminderTexts" SET "title" = NEW."title", "notes" = NEW."notes" WHERE "rowid" = NEW."rowid";
                END
                """#).execute(db)
            try #sql(#"""
                CREATE TRIGGER "reminders_text_delete" AFTER DELETE ON "reminders" BEGIN
                  DELETE FROM "reminderTexts" WHERE "rowid" = OLD."rowid";
                END
                """#).execute(db)
            for (name, event, row) in [("insert", "INSERT", "NEW"), ("delete", "DELETE", "OLD"), ("update", "UPDATE OF \"tagID\"", "NEW")] {
                try #sql(#"""
                    CREATE TRIGGER "remindersTags_text_\#(raw: name)" AFTER \#(raw: event) ON "remindersTags" BEGIN
                      UPDATE "reminderTexts"
                      SET "tags" = (SELECT coalesce(group_concat("tagID", ' '), '') FROM "remindersTags" WHERE "reminderID" = \#(raw: row)."reminderID")
                      WHERE "rowid" = (SELECT "rowid" FROM "reminders" WHERE "id" = \#(raw: row)."reminderID");
                    END
                    """#).execute(db)
            }
        }
        // Completion became a moment: the rows completed so far take the migration's moment, having no other.
        migrator.registerMigration("Completion is a time") { db in
            try #sql(#"DROP INDEX "idx_reminders_completed""#).execute(db)
            try #sql(#"ALTER TABLE "reminders" ADD COLUMN "completedAt" TEXT CHECK ("completedAt" IS NULL OR "completedAt" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]')"#).execute(db)
            try #sql(#"UPDATE "reminders" SET "completedAt" = strftime('%Y-%m-%d %H:%M:%f', 'now') WHERE "completed" = 1"#).execute(db)
            try #sql(#"ALTER TABLE "reminders" DROP COLUMN "completed""#).execute(db)
            try #sql(#"ALTER TABLE "reminders" RENAME COLUMN "completedAt" TO "completed""#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_completed" ON "reminders"("completed") WHERE "completed" IS NOT NULL"#).execute(db)
        }
        migrator.registerMigration("Deleted reminders are kept for thirty days") { db in
            try #sql(#"ALTER TABLE "reminders" ADD COLUMN "deleted" TEXT CHECK ("deleted" IS NULL OR "deleted" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]')"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_deleted" ON "reminders"("deleted") WHERE "deleted" IS NOT NULL"#).execute(db)
        }
        try migrator.migrate(database)
    }

    public static func prepare(_ configuration: inout Configuration) {
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            db.add(function: Reminders.Schema.$hasCaseInsensitivePrefix)
            db.add(collation: Reminders.Schema.$localizedCaseInsensitive)
            db.add(collation: .canonical)
        }
    }

    public static func database(_ configuration: Configuration = Configuration()) throws -> any DatabaseWriter {
        var configuration = configuration
        prepare(&configuration)
        let database = try SQLiteData.defaultDatabase(configuration: configuration)
        try migrate(database)
        return database
    }
}
