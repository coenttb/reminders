public import Reminders
public import SQLiteData

extension Lists {
    /// Creates the Reminders schema in any database; shared by the applications and a future server.
    public static func migrate(_ database: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create lists, reminders (with hasTime, location, repeats), tags, remindersTags, preferences, and listsState (with editing)") { db in
            try #sql("""
                CREATE TABLE "lists" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT NOT NULL DEFAULT '',
                  "color" INTEGER NOT NULL DEFAULT 0,
                  "position" INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "reminders" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                  "title" TEXT NOT NULL DEFAULT '',
                  "notes" TEXT NOT NULL DEFAULT '',
                  "due" TEXT,
                  "hasTime" INTEGER NOT NULL DEFAULT 0,
                  "flagged" INTEGER NOT NULL DEFAULT 0,
                  "priority" INTEGER,
                  "status" INTEGER NOT NULL DEFAULT 0,
                  "position" INTEGER NOT NULL DEFAULT 0,
                  "location" TEXT,
                  "repeats" TEXT NOT NULL DEFAULT 'never'
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "tags" (
                  "title" TEXT COLLATE NOCASE PRIMARY KEY NOT NULL
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "remindersTags" (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                  "reminderID" TEXT NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
                  "tagID" TEXT NOT NULL REFERENCES "tags"("title") ON DELETE CASCADE ON UPDATE CASCADE
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "preferences" (
                  "detailID" TEXT PRIMARY KEY NOT NULL,
                  "ordering" TEXT NOT NULL DEFAULT '',
                  "showCompleted" INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """).execute(db)
            try #sql("""
                CREATE TABLE "listsState" (
                  "id" INTEGER PRIMARY KEY NOT NULL,
                  "detail" TEXT,
                  "editing" TEXT
                ) STRICT
                """).execute(db)
            try #sql(#"CREATE INDEX "idx_reminders_listID" ON "reminders"("listID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_reminderID" ON "remindersTags"("reminderID")"#).execute(db)
            try #sql(#"CREATE INDEX "idx_remindersTags_tagID" ON "remindersTags"("tagID")"#).execute(db)
        }
        try migrator.migrate(database)
    }

    /// The stored lists, or nil before a seed.
    public static func load(_ db: Database) throws -> Lists? {
        guard let state = try Lists.Record.find(1).fetchOne(db) else { return nil }
        let taggings = try Reminder.Tagging.all.fetchAll(db)
        let tagsByReminder = taggings.reduce(into: [Reminder.ID: Set<Tag.ID>]()) { $0[$1.reminderID, default: []].insert($1.tagID) }
        return Lists(
            lists: try Reminder.List.Record.order(by: \.position).fetchAll(db).map(\.list),
            reminders: try Reminder.Record.order(by: \.position).fetchAll(db).map { $0.reminder(tags: tagsByReminder[$0.id] ?? []) },
            tags: Set(try Tag.Record.all.fetchAll(db).map(\.tag)),
            preferences: Dictionary(uniqueKeysWithValues: try Lists.Detail.Preference.Record.all.fetchAll(db).map { ($0.detailID, $0.preference) }),
            detail: state.detail.flatMap(Lists.Detail.init(id:)),
            editing: state.editing
        )
    }

    /// Idempotent: a write triggered before a mount task finishes may already have created the rows.
    public static func seed(_ lists: Lists, in db: Database) throws {
        try persist(lists, in: db)
    }

    /// Writes the whole value: rows are upserted and rows absent from the value are deleted.
    public static func persist(_ lists: Lists, in db: Database) throws {
        for list in lists.lists {
            try Reminder.List.Record.upsert { Reminder.List.Record(list) }.execute(db)
        }
        try Reminder.List.Record.where { !$0.id.in(lists.lists.map(\.id)) }.delete().execute(db)
        for tag in lists.tags {
            try Tag.Record.insert { Tag.Record(tag) } onConflictDoUpdate: { _ in }.execute(db)
        }
        try Tag.Record.where { !$0.title.in(lists.tags.map(\.title)) }.delete().execute(db)
        for reminder in lists.reminders {
            try Reminder.Record.upsert { Reminder.Record(reminder) }.execute(db)
        }
        try Reminder.Record.where { !$0.id.in(lists.reminders.map(\.id)) }.delete().execute(db)
        try Reminder.Tagging.delete().execute(db)
        for reminder in lists.reminders {
            for tag in reminder.sortedTags {
                try Reminder.Tagging.insert { Reminder.Tagging.Draft(reminderID: reminder.id, tagID: tag) }.execute(db)
            }
        }
        for (detailID, preference) in lists.preferences {
            try Lists.Detail.Preference.Record.upsert { Lists.Detail.Preference.Record(detailID: detailID, preference) }.execute(db)
        }
        try Lists.Detail.Preference.Record.where { !$0.detailID.in(Array(lists.preferences.keys)) }.delete().execute(db)
        try Lists.Record.upsert { Lists.Record(detail: lists.detail, editing: lists.editing) }.execute(db)
    }
}
