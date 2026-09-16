public import Reminders
public import Reminders_Interface
public import StructuredQueries
public import Tagged

extension Reminders.Session {
    @Table("session")
    public struct Record: Identifiable, Sendable {
        public let id: Int
        public var filter: Reminders.Filter.Key?
        public var editing: Reminder.ID?

        init(id: Int = 1, filter: Reminders.Filter.Key? = nil, editing: Reminder.ID? = nil) {
            self.id = id
            self.filter = filter
            self.editing = editing
        }
    }
}

extension Reminders.Session.Record {
    public init(id: Int = 1, _ session: Reminders.Session) {
        self.init(id: id, filter: session.filter.map(Reminders.Filter.Key.init), editing: session.editing)
    }
}

extension Reminders.Session.Record {
    public static var state: Where<Reminders.Session.Record> { Reminders.Session.Record.find(1) }

    public static func set(filter: Reminders.Filter?) -> UpdateOf<Reminders.Session.Record> {
        Reminders.Session.Record.find(1).update { $0.filter = filter.map(Reminders.Filter.Key.init) }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminders.Session.Record> {
        Reminders.Session.Record.find(1).update { $0.editing = editing }
    }
}
