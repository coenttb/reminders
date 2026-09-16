public import Foundation
public import Organizing
public import Reminders
public import SQLiteData
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

        public init(_ reminder: Reminder) {
            id = reminder.id
            listID = reminder.list
            title = reminder.title
            notes = reminder.notes
            due = reminder.due?.date
            hasTime = reminder.due?.hasTime ?? false
            flagged = reminder.flagged
            priority = reminder.priority?.rawValue
            status = Self.status(reminder.completion)
            position = reminder.position
            location = reminder.location?.rawValue
            repeats = reminder.repeats.rawValue
            created = reminder.created
        }
    }

    @Table("remindersTags")
    public struct Tagging: Sendable {
        public var reminderID: Reminder.ID
        public var tagID: Tag<Reminder>.ID

        public init(reminderID: Reminder.ID, tagID: Tag<Reminder>.ID) {
            self.reminderID = reminderID
            self.tagID = tagID
        }
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

    public func reminder(tags: Set<Tag<Reminder>.ID>) -> Reminder {
        Reminder(
            id: id,
            list: listID,
            title: title,
            notes: notes,
            due: due.map { Reminder.Due($0, hasTime: hasTime) },
            flagged: flagged,
            priority: priority.flatMap(Reminder.Priority.init(rawValue:)),
            completion: Self.completion(status),
            tags: tags,
            position: position,
            location: location.flatMap(Reminder.Location.init(rawValue:)),
            repeats: Reminder.Repeat(rawValue: repeats) ?? .never,
            created: created
        )
    }
}
