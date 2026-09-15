public import Reminders
public import Reminders_Application
public import SQLiteData
public import Tagged

extension Reminder.Navigation {
    /// One row holding which filter is open and which reminder is being edited in place.
    @Table("listsState")
    public struct Record: Identifiable, Sendable {
        public let id: Int
        @Column("detail")
        public var filter: Reminder.Filter.Key?
        public var editing: Reminder.ID?

        public init(id: Int = 1, _ navigation: Reminder.Navigation) {
            self.id = id
            filter = navigation.filter?.key
            editing = navigation.editing
        }
    }
}

extension Reminder.Navigation.Record {
    public var navigation: Reminder.Navigation {
        Reminder.Navigation(filter: filter?.filter, editing: editing)
    }

    /// The one row holding the open filter and the row being edited.
    public static var state: Where<Reminder.Navigation.Record> { Reminder.Navigation.Record.find(1) }

    public static func set(filter: Reminder.Filter?) -> UpdateOf<Reminder.Navigation.Record> {
        Reminder.Navigation.Record.find(1).update { $0.filter = filter?.key }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminder.Navigation.Record> {
        Reminder.Navigation.Record.find(1).update { $0.editing = editing }
    }
}
