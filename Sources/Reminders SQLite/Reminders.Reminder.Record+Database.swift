public import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Reminder.Record {
    /// Inserts a draft and returns the id the database gave it.
    public static func add(_ draft: Draft, in db: Database) throws -> Reminder.ID {
        guard let id = try Reminder.Record.insert { draft }.returning(\.id).fetchOne(db) else {
            throw DatabaseError(message: "The reminder was not inserted.")
        }
        return id
    }

    /// Inserts a draft at the end of every list and returns its id.
    public static func append(_ draft: Draft, in db: Database) throws -> Reminder.ID {
        let id = try add(draft, in: db)
        try placeLast(id).execute(db)
        return id
    }

    /// A form's save: a new draft is appended with its tags; an existing one has its form columns
    /// and tags replaced, unless the row is gone, in which case nothing is written and `nil` returned.
    public static func save(_ draft: Draft, tags: Set<Tag<Reminder>.ID>, isNew: Bool, in db: Database) throws -> Reminder.ID? {
        if isNew {
            let id = try append(draft, in: db)
            try Reminders.Tagging.attach(tags, to: id, in: db)
            return id
        }
        guard let id = draft.id, try Reminder.Record.find(id).fetchCount(db) > 0 else { return nil }
        try save(draft).execute(db)
        let stored = Set(try Reminders.Tagging.where { $0.reminderID.eq(id) }.select(\.tagID).fetchAll(db))
        let removed = stored.subtracting(tags)
        if !removed.isEmpty { try Reminders.Tagging.detach(removed, from: id).execute(db) }
        try Reminders.Tagging.attach(tags.subtracting(stored), to: id, in: db)
        return id
    }

    public static func reorder(_ ids: [Reminder.ID], in db: Database) throws {
        let stored = Dictionary(uniqueKeysWithValues: try Reminder.Record.where { $0.id.in(ids) }.select { ($0.id, $0.position) }.fetchAll(db))
        let ordered = ids.filter { stored[$0] != nil }
        let positions = ordered.compactMap { stored[$0] }.sorted()
        for (id, position) in zip(ordered, positions) where stored[id] != position {
            try Reminder.Record.find(id).update { $0.position = position }.execute(db)
        }
    }
}
