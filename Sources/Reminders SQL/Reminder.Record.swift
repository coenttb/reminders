public import Foundation
public import Models
public import Reminder
public import Reminders
public import StructuredQueries
public import Tagged

extension Reminder {
    @Table("reminders")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Reminder.ID
        public var listID: List<Reminder>.ID
        public var title: String = ""
        public var notes: String = ""
        @Column("due")
        public var dueDate: Date?
        public var hasTime: Bool = false
        public var flagged: Bool = false
        public var priority: Reminder.Priority?
        public var status: Status = .incomplete
        public var position: Int = 0
        @Column(as: Calendar.RecurrenceRule.JSONRepresentation?.self)
        public var repeats: Calendar.RecurrenceRule?
        public var created: Date

        public init(
            id: Reminder.ID,
            listID: List<Reminder>.ID,
            title: String = "",
            notes: String = "",
            dueDate: Date? = nil,
            hasTime: Bool = false,
            flagged: Bool = false,
            priority: Reminder.Priority? = nil,
            status: Status = .incomplete,
            position: Int = 0,
            repeats: Calendar.RecurrenceRule? = nil,
            created: Date
        ) {
            self.id = id
            self.listID = listID
            self.title = title
            self.notes = notes
            self.dueDate = dueDate
            self.hasTime = hasTime
            self.flagged = flagged
            self.priority = priority
            self.status = status
            self.position = position
            self.repeats = repeats
            self.created = created
        }
    }
}

extension Reminder.Record.Draft: Hashable, Sendable {}

extension Reminder.Record {
    public static func toggle(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update {
            $0.status = Case($0.status).when(Status.incomplete, then: Status.pending).else(Status.incomplete)
        }
    }

    public static var completePending: UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.isPending }.update { $0.status = #bind(Status.completed) }
    }

    public static func placeLast(_ id: Reminder.ID) -> UpdateOf<Reminder.Record> {
        Reminder.Record.find(id).update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    public static func makeRoom(after position: Int) -> UpdateOf<Reminder.Record> {
        Reminder.Record.where { $0.position.gt(position) }.update { $0.position += 1 }
    }

    public static func save(_ draft: Draft) -> InsertOf<Reminder.Record> {
        Reminder.Record.insert {
            draft
        } onConflict: {
            $0.id
        } doUpdate: { row, excluded in
            row.title = excluded.title
            row.notes = excluded.notes
            row.dueDate = excluded.dueDate
            row.hasTime = excluded.hasTime
            row.flagged = excluded.flagged
            row.priority = excluded.priority
            row.listID = excluded.listID
            row.repeats = excluded.repeats
        }
    }

    public static func deleteCompleted(in filter: Reminders.Filter, today: Range<Date>) -> DeleteOf<Reminder.Record> {
        Reminder.Record.where { $0.isDone && $0.belongs(to: filter, today: today) }.delete()
    }
}
