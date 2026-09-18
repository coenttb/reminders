public import Foundation
public import Models
public import Reminder
public import StructuredQueries
public import Tagged

extension Reminder {
    @Table("reminders")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Reminder.ID
        public var listID: Models.List<Reminder>.ID
        public var title: String = ""
        public var notes: String = ""
        @Column("due")
        public var dueDate: Date?
        public var hasTime: Bool = false
        public var flagged: Bool = false
        public var priority: Reminder.Priority?
        public var completed: Date?
        public var deleted: Date?
        public var position: Int = 0
        @Column(as: Calendar.RecurrenceRule.JSONRepresentation?.self)
        public var repeats: Calendar.RecurrenceRule?
        public var created: Date

        public init(
            id: Reminder.ID,
            listID: Models.List<Reminder>.ID,
            title: String = "",
            notes: String = "",
            dueDate: Date? = nil,
            hasTime: Bool = false,
            flagged: Bool = false,
            priority: Reminder.Priority? = nil,
            completed: Date? = nil,
            deleted: Date? = nil,
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
            self.completed = completed
            self.deleted = deleted
            self.position = position
            self.repeats = repeats
            self.created = created
        }
    }
}

extension Reminder.Record.Draft: Hashable, Sendable {}
