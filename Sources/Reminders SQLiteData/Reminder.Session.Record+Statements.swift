public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder.Session.Record {
    public static var state: Where<Reminder.Session.Record> { Reminder.Session.Record.find(1) }

    public static func set(filter: Reminder.Filter?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.filter = filter.map(Reminder.Filter.Key.init) }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminder.Session.Record> {
        Reminder.Session.Record.find(1).update { $0.editing = editing }
    }
}
