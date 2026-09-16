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
