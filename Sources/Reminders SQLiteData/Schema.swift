import Foundation
import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData

extension Reminder {
    /// The Reminders database: its tables, the connection setup they need, and the sample
    /// that fills a first run.
    public enum Schema {}
}

extension Reminder.Schema {
    /// Creates the Reminders schema in any database, or brings an older one up to date; shared
    /// by the applications and a future server. `upTo` stops at an earlier migration, for
    /// tests that upgrade from it.
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
        // A tag's title is its key case-insensitively as Swift compares, not as SQLite's NOCASE
        // folds ASCII: "Café" and "CAFÉ" are one tag. The table is rebuilt on the collation the
        // connection installs; titles that were two tags and are now one keep the older, and
        // the links follow it. The links are rebuilt too, so two links become one.
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
        // The database is the source of truth, so what a row may hold is the schema's rule, not
        // the reader's tolerance: a due date is stored text in one format, a status is one of the
        // three, a priority one of the three or none. A writer that breaks the rule is refused;
        // rows that broke it before the rule existed are brought back inside it (a malformed
        // date is no date, an unknown status is incomplete, an unknown priority none) rather
        // than left to fail every read of their screen.
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
        // The Creation Date ordering needs a timestamp. Rows from before the column are dated
        // at the epoch, so among themselves they keep the manual order.
        migrator.registerMigration("Record when a reminder was created") { db in
            try #sql(#"ALTER TABLE "reminders" ADD COLUMN "created" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '1970-01-01 00:00:00.000' CHECK ("created" GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]')"#).execute(db)
        }
        // The smart lists and the grace timer filter by these; without the indexes Today and the
        // pending set scan every reminder (RESEARCH.md, scale investigation).
        migrator.registerMigration("Index the due date and the status") { db in
            try #sql(#"CREATE INDEX "idx_reminders_due" ON "reminders"("due") WHERE "due" IS NOT NULL"#).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_status" ON "reminders"("status")"#).execute(db)
        }
        // The search compared every title and notes through a Swift function, twice per read at
        // 100,000 rows (RESEARCH.md, device measurement). The folded text is kept in a column
        // the triggers maintain, and matched with SQLite's `instr`.
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

    /// The connection setup every Reminders database needs: foreign keys, so a list takes its
    /// reminders with it, and the Swift text rules the queries call on. The tags table's key is
    /// declared on the `localizedCaseInsensitive` collation, so a connection without it cannot
    /// use that table: every Reminders database is opened through here.
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

    /// An in-memory database with the schema, for tests.
    public static func inMemoryDatabase() throws -> DatabaseQueue {
        var configuration = Configuration()
        prepare(&configuration)
        let database = try DatabaseQueue(configuration: configuration)
        try migrate(database)
        return database
    }
}

extension Reminder.Sample {
    /// The first run: fills an uninitialised database with the sample. The state row is written
    /// by the first initialisation and never deleted, so a database initialised before is left
    /// alone whatever it holds, and a failed read throws rather than counting as a first run.
    public static func initialize(with sample: Self, in db: Database) throws {
        guard try Reminder.Session.Record.state.fetchCount(db) == 0 else { return }
        try replace(with: sample, in: db)
    }

    public func initialize(in db: Database) throws { try Self.initialize(with: self, in: db) }

    /// The explicit reset: everything the database holds is replaced by the sample, in one
    /// transaction.
    public static func replace(with sample: Self, in db: Database) throws {
        try Reminder.Tagging.delete().execute(db)
        try Reminder.Record.delete().execute(db)
        try List<Reminder>.Record.delete().execute(db)
        try Tag<Reminder>.Record.delete().execute(db)
        try Reminder.Filter.Preference.Record.delete().execute(db)
        // Rows go in by the few hundred: a generated sample has a hundred thousand reminders,
        // and one statement per row was the whole seeding time.
        for lists in sample.lists.chunks(of: 200) {
            try List<Reminder>.Record.insert { lists.map(List<Reminder>.Record.init) }.execute(db)
        }
        for tags in sample.tags.sorted { $0.title < $1.title }.chunks(of: 500) {
            try Tag<Reminder>.Record.insert { tags.map(Tag<Reminder>.Record.init) }.execute(db)
        }
        for reminders in sample.reminders.chunks(of: 200) {
            try Reminder.Record.insert { reminders.map(Reminder.Record.init) }.execute(db)
        }
        // A sample's tags are canonical by construction, so the links need no title lookup.
        let taggings = sample.reminders.flatMap { reminder in reminder.tags.sorted().map { Reminder.Tagging(reminderID: reminder.id, tagID: $0) } }
        for chunk in taggings.chunks(of: 500) {
            try Reminder.Tagging.insert { Array(chunk) }.execute(db)
        }
        try Reminder.Session.Record.upsert { Reminder.Session.Record(Reminder.Session()) }.execute(db)
    }

    public func replace(in db: Database) throws { try Self.replace(with: self, in: db) }
}

extension Collection where Index == Int {
    /// Consecutive slices of at most `size` elements.
    fileprivate func chunks(of size: Int) -> [SubSequence] {
        stride(from: startIndex, to: endIndex, by: size).map { self[$0..<Swift.min($0 + size, endIndex)] }
    }
}
