public import Foundation
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder.Record {
    /// A reminder with its tags and its list's color, as the screens read it.
    @Selection
    public struct Row: Sendable {
        public let reminder: Reminder.Record
        public let tags: String?
        public let color: Int64

        public var value: Reminder { reminder.reminder(tags: Reminder.Record.tags(from: tags)) }
        public var listColor: Reminder.List.Color { Reminder.List.Color(hex: color) }
    }

    /// Every reminder as a `Row`, joined to its list; narrow with `where`, `find`, and `order`
    /// before selecting, or apply them to the rows through the two-table closures.
    public static var rows: Select<Row, Reminder.Record, Reminder.List.Record> {
        Reminder.Record.all.rows()
    }

    /// The circle tap: incomplete starts completing; completing or completed reverts to incomplete.
    public static func toggle(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update {
            $0.status = Case($0.status)
                .when(Reminder.Status.incomplete.rawValue, then: Reminder.Status.completing.rawValue)
                .else(Reminder.Status.incomplete.rawValue)
        }
    }

    /// The grace timer elapsed: every reminder still completing is now completed. One that was
    /// reverted meanwhile is incomplete and untouched; one deleted meanwhile is simply absent.
    public static var completeCompleting: UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.isCompleting }.update { $0.status = Reminder.Status.completed.rawValue }
    }

    /// Puts a reminder at the end of the manual order.
    public static func placeLast(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    /// Moves every reminder after a position down one place, so a row can be inserted directly
    /// beneath it.
    public static func makeRoom(after position: Int) -> UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.position.gt(position) }.update { $0.position += 1 }
    }

    /// Reorders the reminders as the user dragged them: the positions those reminders hold are
    /// dealt out again in the new order, so the rest of the manual order is untouched.
    public static func reorder(_ ids: [Reminder.ID], in db: Database) throws {
        let stored = Dictionary(uniqueKeysWithValues: try Reminder.Record.where { $0.id.in(ids) }.select { ($0.id, $0.position) }.fetchAll(db))
        let ordered = ids.filter { stored[$0] != nil }
        let positions = ordered.compactMap { stored[$0] }.sorted()
        for (id, position) in zip(ordered, positions) where stored[id] != position {
            try Reminder.Record.find(id).update { $0.position = position }.execute(db)
        }
    }

    /// The columns an edit changed, and nothing else, so a change made elsewhere to another
    /// field survives; nil when no column differs. The status is the grace timer's, never a
    /// draft's, and the tags are links: see `Reminder.Tagging.attach` and `detach`.
    public static func changes(from original: Reminder, to draft: Reminder) -> UpdateOf<Reminder.Record>? {
        var same = original
        same.status = draft.status
        same.tags = draft.tags
        guard same != draft else { return nil }
        return Reminder.Record.find(original.id).update { row in
            if draft.list != original.list { row.listID = draft.list }
            if draft.title != original.title { row.title = draft.title }
            if draft.notes != original.notes { row.notes = draft.notes }
            if draft.due != original.due { row.due = draft.due }
            if draft.hasTime != original.hasTime { row.hasTime = draft.hasTime }
            if draft.flagged != original.flagged { row.flagged = draft.flagged }
            if draft.priority != original.priority { row.priority = draft.priority?.rawValue }
            if draft.position != original.position { row.position = draft.position }
            if draft.location != original.location { row.location = draft.location?.rawValue }
            if draft.repeats != original.repeats { row.repeats = draft.repeats.rawValue }
        }
    }

    /// Deletes the completed reminders a search matches, optionally only those due before a
    /// cutoff. One still in its grace period is kept, so the tap can be undone.
    public static func deleteCompleted(matching search: Lists.Search, dueBefore cutoff: Date?) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isDone && $0.matches(search) }
            .where { if let cutoff { #sql("\($0.due) < \(cutoff)") } }
            .delete()
    }
}

extension Where<Reminder.Record> {
    /// The reminders as rows with their tags and list color.
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, Reminder.List.Record> {
        join(Reminder.List.Record.all) { $0.listID.eq($1.id) }
            .select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tagList, color: $1.color) }
    }
}

extension Select<(), Reminder.Record, ()> {
    /// The reminders as rows with their tags and list color.
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, Reminder.List.Record> {
        join(Reminder.List.Record.all) { $0.listID.eq($1.id) }
            .select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tagList, color: $1.color) }
    }
}

extension Reminder.Tagging {
    /// Links a reminder to tags by title. A title the tags table knows in another case attaches
    /// the known tag rather than a twin; an unknown one is created.
    public static func attach(_ tags: Set<Tag.ID>, to id: Reminder.ID, in db: Database) throws {
        for tag in tags.sorted() {
            guard let canonical = try Tag.Record.add(tag.rawValue, in: db) else { continue }
            let linked = try Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(canonical) }.fetchCount(db) > 0
            if !linked {
                try Reminder.Tagging.insert { Reminder.Tagging(reminderID: id, tagID: canonical) }.execute(db)
            }
        }
    }

    /// Unlinks tags from a reminder; the tags themselves stay.
    public static func detach(_ tags: Set<Tag.ID>, from id: Reminder.ID) -> DeleteOf<Reminder.Tagging> {
        Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.delete()
    }
}
