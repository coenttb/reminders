public import Foundation
public import Organizing
public import Tagged

extension Reminders {
    public struct Reminder: Identifiable, Hashable, Sendable {
        public var id: Tagged<Reminder, UUID>
        public var list: List<Reminder>.ID
        public var title: String
        public var notes: String
        public var due: Due?
        public var flagged: Bool
        public var priority: Priority?
        public var completion: Completion
        public var tags: Set<Tag<Reminder>.ID>
        public var position: Int
        public var location: Location?
        public var repeats: Repeat
        public var created: Date

        public init(
            id: ID,
            list: List<Reminder>.ID,
            title: String = "",
            notes: String = "",
            due: Due? = nil,
            flagged: Bool = false,
            priority: Priority? = nil,
            completion: Completion = .incomplete,
            tags: Set<Tag<Reminder>.ID> = [],
            position: Int = 0,
            location: Location? = nil,
            repeats: Repeat = .never,
            created: Date
        ) {
            self.id = id
            self.list = list
            self.title = title
            self.notes = notes
            self.due = due
            self.flagged = flagged
            self.priority = priority
            self.completion = completion
            self.tags = tags
            self.position = position
            self.location = location
            self.repeats = repeats
            self.created = created
        }
    }
}

public typealias Reminder = Reminders.Reminder
