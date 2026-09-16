import Foundation
public import Reminders
import Reminders_SQL
public import SQLiteData

extension Reminders {
    public enum Schema {}
}

extension Reminders.Schema {
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
        migrator.registerMigration("Let the database mint ids") { db in
            try #sql("""
                CREATE TABLE "lists_new" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "color" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql(#"INSERT INTO "lists_new" SELECT "id", "title", "color", "position" FROM "lists" ORDER BY "rowid""#).execute(db)
            try #sql(#"DROP TABLE "lists""#).execute(db)
            try #sql(#"ALTER TABLE "lists_new" RENAME TO "lists""#).execute(db)
            try #sql("""
                CREATE TABLE "reminders_new" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
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
                  "repeats" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'never',
                  "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "searchText" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                ) STRICT
                """).execute(db)
            try #sql("""
                INSERT INTO "reminders_new"
                SELECT "id", "listID", "title", "notes", "due", "hasTime", "flagged", "priority", "status", "position", "location", "repeats", "created", "searchText"
                FROM "reminders" ORDER BY "rowid"
                """).execute(db)
            try #sql(#"DROP TABLE "reminders""#).execute(db)
            try #sql(#"ALTER TABLE "reminders_new" RENAME TO "reminders""#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_status" ON "reminders"("status")"#).execute(db)
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
        migrator.registerMigration("Store a repeat as a recurrence rule and drop the location") { db in
            try #sql("""
                CREATE TABLE "reminders_new" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "notes" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "due" TEXT CHECK ("due" IS NULL OR "due" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "hasTime" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "flagged" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "priority" INTEGER CHECK ("priority" IS NULL OR "priority" IN (1, 2, 3)),
                  "status" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0 CHECK ("status" IN (0, 1, 2)),
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "repeats" TEXT CHECK ("repeats" IS NULL OR json_valid("repeats")),
                  "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "searchText" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                ) STRICT
                """).execute(db)
            try #sql("""
                INSERT INTO "reminders_new"
                SELECT "id", "listID", "title", "notes", "due", "hasTime", "flagged", "priority", "status", "position", NULL, "created", "searchText"
                FROM "reminders" ORDER BY "rowid"
                """).execute(db)
            let encoder = JSONEncoder()
            for frequency in [Calendar.RecurrenceRule.Frequency.daily, .weekly, .monthly, .yearly] {
                let rule = String(decoding: try encoder.encode(Calendar.RecurrenceRule(calendar: .current, frequency: frequency)), as: UTF8.self)
                try #sql("""
                    UPDATE "reminders_new" SET "repeats" = \(bind: rule)
                    WHERE "id" IN (SELECT "id" FROM "reminders" WHERE "repeats" = \(bind: Self.legacyRepeatName(frequency)))
                    """).execute(db)
            }
            try #sql(#"DROP TABLE "reminders""#).execute(db)
            try #sql(#"ALTER TABLE "reminders_new" RENAME TO "reminders""#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_status" ON "reminders"("status")"#).execute(db)
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
        migrator.registerMigration("Store completion as a flag") { db in
            try #sql("""
                CREATE TABLE "reminders_new" (
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
                  "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]'),
                  "searchText" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                ) STRICT
                """).execute(db)
            try #sql("""
                INSERT INTO "reminders_new"
                SELECT "id", "listID", "title", "notes", "due", "hasTime", "flagged", "priority",
                  CASE WHEN "status" IN (1, 2) THEN 1 ELSE 0 END,
                  "position", "repeats", "created", "searchText"
                FROM "reminders" ORDER BY "rowid"
                """).execute(db)
            try #sql(#"DROP TABLE "reminders""#).execute(db)
            try #sql(#"ALTER TABLE "reminders_new" RENAME TO "reminders""#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_completed" ON "reminders"("completed")"#).execute(db)
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

    private static func legacyRepeatName(_ frequency: Calendar.RecurrenceRule.Frequency) -> String {
        switch frequency {
        case .daily: "daily"
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .yearly: "yearly"
        case .minutely, .hourly: ""
        @unknown default: ""
        }
    }

    public static func prepare(_ configuration: inout Configuration) {
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            db.add(function: Reminders.Schema.$localizedCaseInsensitiveContains)
            db.add(function: Reminders.Schema.$hasCaseInsensitivePrefix)
            db.add(function: Reminders.Schema.$searchFolded)
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
