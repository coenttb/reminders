public import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminder {
    @Table("reminders")
    public struct Record: Identifiable, Sendable {
        public let id: Reminder.ID
        public var listID: List<Reminder>.ID
        public var title = ""
        public var notes = ""
        public var due: Date?
        public var hasTime = false
        public var flagged = false
        public var priority: Int?
        public var status = 0
        public var position = 0
        public var location: String?
        public var repeats = "never"
        public var created: Date

        init(
            id: Reminder.ID,
            listID: List<Reminder>.ID,
            title: String = "",
            notes: String = "",
            due: Date? = nil,
            hasTime: Bool = false,
            flagged: Bool = false,
            priority: Int? = nil,
            status: Int = 0,
            position: Int = 0,
            location: String? = nil,
            repeats: String = "never",
            created: Date
        ) {
            self.id = id
            self.listID = listID
            self.title = title
            self.notes = notes
            self.due = due
            self.hasTime = hasTime
            self.flagged = flagged
            self.priority = priority
            self.status = status
            self.position = position
            self.location = location
            self.repeats = repeats
            self.created = created
        }
    }
}

extension Reminder.Record {
    public init(_ reminder: Reminder) {
        self.init(
            id: reminder.id,
            listID: reminder.list,
            title: reminder.title,
            notes: reminder.notes,
            due: reminder.due?.date,
            hasTime: reminder.due?.hasTime ?? false,
            flagged: reminder.flagged,
            priority: reminder.priority?.rawValue,
            status: Self.status(reminder.completion),
            position: reminder.position,
            location: reminder.location?.rawValue,
            repeats: reminder.repeats.rawValue,
            created: reminder.created
        )
    }
}

extension Reminder.Record {
    static let incomplete = 0
    static let completed = 1
    static let pending = 2

    static func status(_ completion: Reminder.Completion) -> Int {
        completion == .completed ? completed : incomplete
    }

    static func completion(_ status: Int) -> Reminder.Completion {
        status == incomplete ? .incomplete : .completed
    }
}

extension Reminder.Record {
    static let tagSeparator = String(Character.unitSeparator)

    static func tags(from list: String?) -> Set<Tag<Reminder>.ID> {
        Set((list ?? "").split(separator: tagSeparator).map { Tag<Reminder>.ID(String($0)) })
    }
}

extension Reminder.Record {
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
            .where { if let cutoff { $0.due.lt(Date?.some(cutoff)) } }
            .delete()
    }
}
