public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder.Session {
    @Table("session")
    public struct Record: Identifiable, Sendable {
        public let id: Int
        public var filter: Reminder.Filter.Key?
        public var editing: Reminder.ID?

        init(id: Int = 1, filter: Reminder.Filter.Key? = nil, editing: Reminder.ID? = nil) {
            self.id = id
            self.filter = filter
            self.editing = editing
        }
    }
}

extension Reminder.Session.Record {
    public init(id: Int = 1, _ session: Reminder.Session) {
        self.init(id: id, filter: session.filter.map(Reminder.Filter.Key.init), editing: session.editing)
    }
}

extension Reminder.Session.Record {
    public static var state: Where<Reminder.Session.Record> { Reminder.Session.Record.find(1) }

    public static func set(filter: Reminder.Filter?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.filter = filter.map(Reminder.Filter.Key.init) }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.editing = editing }
    }
}
