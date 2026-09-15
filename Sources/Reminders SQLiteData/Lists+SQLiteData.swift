public import Reminders
public import SQLiteData

extension Lists {
    /// Creates the Reminders schema in any database; shared by the applications and a future server.
    public static func migrate(_ database: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create the Reminders tables") { db in
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
                  "reminderID" TEXT NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
                  "tagID" TEXT NOT NULL REFERENCES "tags"("title") ON DELETE CASCADE ON UPDATE CASCADE,
                  PRIMARY KEY ("reminderID", "tagID")
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
            // A key no detail answers to, left by an older schema, is noise and stays behind.
            preferences: Dictionary(uniqueKeysWithValues: try Lists.Detail.Preference.Record.all.fetchAll(db).filter { Lists.Detail(id: $0.detailID) != nil }.map { ($0.detailID, $0.preference) }),
            detail: state.detail.flatMap(Lists.Detail.init(id:)),
            editing: state.editing
        )
    }

    /// Idempotent: a write triggered before a mount task finishes may already have created the rows.
    public static func seed(_ lists: Lists, in db: Database) throws {
        try persist(lists, in: db)
    }

    /// Writes the value: rows that differ from what the database holds are upserted, rows
    /// absent from the value are deleted, and nothing else is touched. The comparison reads
    /// the stored value inside the same transaction, so a write that was cancelled and rolled
    /// back before this one cannot leave a change behind; a baseline carried in memory could.
    public static func persist(_ lists: Lists, in db: Database) throws {
        let stored = try load(db)
        for list in lists.lists where stored?.list(list.id) != list {
            try Reminder.List.Record.upsert { Reminder.List.Record(list) }.execute(db)
        }
        let goneLists = Set((stored?.lists ?? []).map(\.id)).subtracting(lists.lists.map(\.id))
        if !goneLists.isEmpty {
            try Reminder.List.Record.where { $0.id.in(goneLists) }.delete().execute(db)
        }
        // Tags gone from the value go first: the key is case-insensitive, so a tag renamed
        // only in case would otherwise be deleted along with its old spelling.
        let goneTags = (stored?.tags ?? []).subtracting(lists.tags)
        if !goneTags.isEmpty {
            try Tag.Record.where { $0.title.in(goneTags.map(\.title)) }.delete().execute(db)
        }
        for tag in lists.tags.subtracting(stored?.tags ?? []) {
            try Tag.Record.insert { Tag.Record(tag) } onConflictDoUpdate: { $0.title = $1.title }.execute(db)
        }
        for reminder in lists.reminders {
            let record = Reminder.Record(reminder)
            guard stored?.reminder(reminder.id).map({ Reminder.Record($0).isStored(as: record) }) != true else { continue }
            try Reminder.Record.upsert { record }.execute(db)
        }
        let goneReminders = Set((stored?.reminders ?? []).map(\.id)).subtracting(lists.reminders.map(\.id))
        if !goneReminders.isEmpty {
            try Reminder.Record.where { $0.id.in(goneReminders) }.delete().execute(db)
        }
        for reminder in lists.reminders where stored?.reminder(reminder.id)?.tags != reminder.tags {
            try Reminder.Tagging.where { $0.reminderID.eq(reminder.id) }.delete().execute(db)
            for tag in reminder.sortedTags {
                try Reminder.Tagging.insert { Reminder.Tagging(reminderID: reminder.id, tagID: tag) }.execute(db)
            }
        }
        for (detailID, preference) in lists.preferences where stored?.preferences[detailID] != preference {
            try Lists.Detail.Preference.Record.upsert { Lists.Detail.Preference.Record(detailID: detailID, preference) }.execute(db)
        }
        let gonePreferences = Set(stored.map { Array($0.preferences.keys) } ?? []).subtracting(lists.preferences.keys)
        if !gonePreferences.isEmpty {
            try Lists.Detail.Preference.Record.where { $0.detailID.in(gonePreferences) }.delete().execute(db)
        }
        if stored == nil || stored?.detail != lists.detail || stored?.editing != lists.editing {
            try Lists.Record.upsert { Lists.Record(detail: lists.detail, editing: lists.editing) }.execute(db)
        }
    }
}
