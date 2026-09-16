public import Reminder
public import Reminders
public import Reminders_Session
public import StructuredQueries
public import Tagged

extension Reminders.Session {
    @Table("session")
    public struct Record: Hashable, Sendable {
        public let id: Int
        public var filter: Reminders.Filter.Key?
        public var editing: Reminder.ID?

        public init(id: Int = 1, filter: Reminders.Filter.Key? = nil, editing: Reminder.ID? = nil) {
            self.id = id
            self.filter = filter
            self.editing = editing
        }
    }
}

extension Reminders.Session.Record: Identifiable {}

extension Reminders.Session {
    public init(_ record: Record, editing: Reminders.Placement?) {
        self.init(filter: record.filter.flatMap(Reminders.Filter.init(key:)), editing: editing)
    }
}

extension Reminders.Session.Record {
    public static var current: Where<Self> { Self.find(1) }

    public static func set(filter: Reminders.Filter?) -> UpdateOf<Self> {
        Self.find(1).update { $0.filter = filter.map(Reminders.Filter.Key.init) }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Self> {
        Self.find(1).update { $0.editing = editing }
    }
}
