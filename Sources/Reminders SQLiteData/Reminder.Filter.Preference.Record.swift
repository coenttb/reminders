public import Reminders
public import Reminders_Application
public import SQLiteData

extension Reminder.Filter.Preference {
    @Table("preferences")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var key: Reminder.Filter.Key
        public var ordering = ""
        public var showCompleted = false

        public var id: Reminder.Filter.Key { key }

        public init(key: Reminder.Filter.Key, _ preference: Reminder.Filter.Preference) {
            self.key = key
            ordering = preference.ordering.rawValue
            showCompleted = preference.showCompleted
        }
    }
}

extension Reminder.Filter.Preference {
    public init(_ record: Reminder.Filter.Preference.Record) {
        self.init(ordering: Reminder.Ordering(rawValue: record.ordering) ?? .dueDate, showCompleted: record.showCompleted)
    }
}

extension Reminder.Filter.Preference.Record {
    public var preference: Reminder.Filter.Preference { Reminder.Filter.Preference(self) }

    public static func preference(for filter: Reminder.Filter) -> Where<Reminder.Filter.Preference.Record> {
        Reminder.Filter.Preference.Record.find(filter.key)
    }

    public static func set(ordering: Reminder.Ordering, for filter: Reminder.Filter) -> InsertOf<Reminder.Filter.Preference.Record> {
        var preference = filter.defaultPreference
        preference.ordering = ordering
        return Reminder.Filter.Preference.Record.insert {
            Reminder.Filter.Preference.Record(key: filter.key, preference)
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    public static func toggleShowCompleted(for filter: Reminder.Filter) -> InsertOf<Reminder.Filter.Preference.Record> {
        var preference = filter.defaultPreference
        preference.showCompleted.toggle()
        return Reminder.Filter.Preference.Record.insert {
            Reminder.Filter.Preference.Record(key: filter.key, preference)
        } onConflict: {
            $0.key
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}
