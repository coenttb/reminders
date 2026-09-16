public import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder.Record {
    @Selection
    public struct Row: Sendable {
        public let reminder: Reminder.Record
        public let tags: String?
        public let color: Color.Hex

        public var value: Reminder { reminder.reminder(tags: Reminder.Record.tags(from: tags)) }
        public var listColor: Color { color.color }
    }

    public static var rows: Select<Row, Reminder.Record, List<Reminder>.Record> {
        Reminder.Record.all.rows()
    }

    public static func toggle(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update {
            $0.status = Case($0.status)
                .when(Reminder.Record.incomplete, then: Reminder.Record.pending)
                .else(Reminder.Record.incomplete)
        }
    }

    public static var completePending: UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.isPending }.update { $0.status = Reminder.Record.completed }
    }

    public static func placeLast(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    public static func makeRoom(after position: Int) -> UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.position.gt(position) }.update { $0.position += 1 }
    }

    public static func reorder(_ ids: [Reminder.ID], in db: Database) throws {
        let stored = Dictionary(uniqueKeysWithValues: try Reminder.Record.where { $0.id.in(ids) }.select { ($0.id, $0.position) }.fetchAll(db))
        let ordered = ids.filter { stored[$0] != nil }
        let positions = ordered.compactMap { stored[$0] }.sorted()
        for (id, position) in zip(ordered, positions) where stored[id] != position {
            try Reminder.Record.find(id).update { $0.position = position }.execute(db)
        }
    }

    public static func changes(from original: Reminder, to draft: Reminder) -> UpdateOf<Reminder.Record>? {
        var same = original
        same.completion = draft.completion
        same.tags = draft.tags
        guard same != draft else { return nil }
        return Reminder.Record.find(original.id).update { row in
            if draft.list != original.list { row.listID = draft.list }
            if draft.title != original.title { row.title = draft.title }
            if draft.notes != original.notes { row.notes = draft.notes }
            if draft.due != original.due {
                row.due = draft.due?.date
                row.hasTime = draft.due?.hasTime ?? false
            }
            if draft.flagged != original.flagged { row.flagged = draft.flagged }
            if draft.priority != original.priority { row.priority = draft.priority?.rawValue }
            if draft.position != original.position { row.position = draft.position }
            if draft.location != original.location { row.location = draft.location?.rawValue }
            if draft.repeats != original.repeats { row.repeats = draft.repeats.rawValue }
        }
    }

    public static func deleteCompleted(in filter: Reminder.Filter, today: Range<Date>) -> DeleteOf<Reminder.Record> {
        Reminder.Record.where { $0.isDone && $0.belongs(to: filter, today: today) }.delete()
    }

    public static func deleteCompleted(matching search: Reminder.Search, dueBefore cutoff: Date?) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isDone && $0.matches(search) }
            .where { if let cutoff { #sql("\($0.due) < \(cutoff)") } }
            .delete()
    }
}

extension Where<Reminder.Record> {
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, List<Reminder>.Record> {
        join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
            .select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tagList, color: $1.color) }
    }
}

extension Select<(), Reminder.Record, ()> {
    public func rows() -> Select<Reminder.Record.Row, Reminder.Record, List<Reminder>.Record> {
        join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
            .select { Reminder.Record.Row.Columns(reminder: $0, tags: $0.tagList, color: $1.color) }
    }
}

extension Reminder.Tagging {
    public static func attach(_ tags: Set<Tag<Reminder>.ID>, to id: Reminder.ID, in db: Database) throws {
        for tag in tags.sorted() {
            guard let canonical = try Tag<Reminder>.Record.add(tag.rawValue, in: db) else { continue }
            let linked = try Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(canonical) }.fetchCount(db) > 0
            if !linked {
                try Reminder.Tagging.insert { Reminder.Tagging(reminderID: id, tagID: canonical) }.execute(db)
            }
        }
    }

    public static func detach(_ tags: Set<Tag<Reminder>.ID>, from id: Reminder.ID) -> DeleteOf<Reminder.Tagging> {
        Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.delete()
    }
}
