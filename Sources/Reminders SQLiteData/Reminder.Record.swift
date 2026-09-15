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
        public var hasTime = false
        public var flagged = false
        public var priority: Int?
        public var status = 0
        public var position = 0
        public var location: String?
        public var repeats = "never"

        public init(_ reminder: Reminder) {
            id = reminder.id
            listID = reminder.list
            title = reminder.title
            notes = reminder.notes
            due = reminder.due
            hasTime = reminder.hasTime
            flagged = reminder.flagged
            priority = reminder.priority?.rawValue
            status = reminder.status.rawValue
            position = reminder.position
            location = reminder.location?.rawValue
            repeats = reminder.repeats.rawValue
        }
    }

    /// One reminder-to-tag link; the many-to-many the domain expresses as `Reminder.tags`.
    /// The pair is the key, so there is no surrogate to grow.
    @Table("remindersTags")
    public struct Tagging: Sendable {
        public var reminderID: Reminder.ID
        public var tagID: Tag.ID

        public init(reminderID: Reminder.ID, tagID: Tag.ID) {
            self.reminderID = reminderID
            self.tagID = tagID
        }
    }
}

extension Reminder.Record {
    /// Whether a row already holds this reminder. Dates are stored to the millisecond, so a
    /// value that differs from the row only below that is the same row, not a change.
    public func isStored(as other: Reminder.Record) -> Bool {
        id == other.id && listID == other.listID && title == other.title && notes == other.notes
            && hasTime == other.hasTime && flagged == other.flagged && priority == other.priority
            && status == other.status && position == other.position && location == other.location
            && repeats == other.repeats && sameInstant(due, other.due)
    }

    private func sameInstant(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (l?, r?): Swift.abs(l.timeIntervalSince(r)) < 0.001
        default: false
        }
    }

    public func reminder(tags: Set<Tag.ID>) -> Reminder {
        Reminder(
            id: id,
            list: listID,
            title: title,
            notes: notes,
            due: due,
            hasTime: hasTime,
            flagged: flagged,
            priority: priority.flatMap(Reminder.Priority.init(rawValue:)),
            status: Reminder.Status(rawValue: status) ?? .incomplete,
            tags: tags,
            position: position,
            location: location.flatMap(Reminder.Location.init(rawValue:)),
            repeats: Reminder.Repeat(rawValue: repeats) ?? .never
        )
    }
}
