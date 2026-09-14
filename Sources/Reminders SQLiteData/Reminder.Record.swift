public import Foundation
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder {
    /// The stored form of a reminder; tags are rows of `Reminder.Tagging`.
    @Table("reminders")
    public struct Record: Identifiable, Sendable {
        public let id: Reminder.ID
        public var listID: Reminder.List.ID
        public var title = ""
        public var notes = ""
        public var due: Date?
        public var flagged = false
        public var priority: Int?
        public var status = 0
        public var position = 0

        public init(_ reminder: Reminder) {
            id = reminder.id
            listID = reminder.list
            title = reminder.title
            notes = reminder.notes
            due = reminder.due
            flagged = reminder.flagged
            priority = reminder.priority?.rawValue
            status = reminder.status.rawValue
            position = reminder.position
        }
    }

    /// One reminder-to-tag link; the many-to-many the domain expresses as `Reminder.tags`.
    @Table("remindersTags")
    public struct Tagging: Identifiable, Sendable {
        public let id: Int
        public var reminderID: Reminder.ID
        public var tagID: Tag.ID
    }
}

extension Reminder.Record {
    public func reminder(tags: Set<Tag.ID>) -> Reminder {
        Reminder(
            id: id,
            list: listID,
            title: title,
            notes: notes,
            due: due,
            flagged: flagged,
            priority: priority.flatMap(Reminder.Priority.init(rawValue:)),
            status: Reminder.Status(rawValue: status) ?? .incomplete,
            tags: tags,
            position: position
        )
    }
}
