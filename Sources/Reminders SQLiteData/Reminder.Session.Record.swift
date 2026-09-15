public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder.Session {
    /// One row holding which filter is open and which reminder is being edited in place.
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

extension Reminder.Session.Record {
    public var session: Reminder.Session {
        Reminder.Session(filter: filter?.filter, editing: editing)
    }

    /// The one row holding the open filter and the row being edited.
    public static var state: Where<Reminder.Session.Record> { Reminder.Session.Record.find(1) }

    public static func set(filter: Reminder.Filter?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.filter = filter?.key }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.editing = editing }
    }
}
