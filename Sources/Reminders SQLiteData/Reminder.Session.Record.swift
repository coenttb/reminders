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

        public init(id: Int = 1, _ session: Reminder.Session) {
            self.id = id
            filter = session.filter?.key
            editing = session.editing
        }
    }
}

extension Reminder.Session {
    public init(_ record: Reminder.Session.Record) {
        self.init(filter: record.filter?.filter, editing: record.editing)
    }
}

extension Reminder.Session.Record {
    public var session: Reminder.Session { Reminder.Session(self) }

    public static var state: Where<Reminder.Session.Record> { Reminder.Session.Record.find(1) }

    public static func set(filter: Reminder.Filter?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.filter = filter?.key }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.editing = editing }
    }
}
