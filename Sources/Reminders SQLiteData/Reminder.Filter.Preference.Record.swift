public import Reminders
public import Reminders_Interface
public import SQLiteData

extension Reminders.Filter.Preference {
    @Table("preferences")
    public struct Record: Sendable {
        @Column(primaryKey: true)
        public var key: Reminders.Filter.Key
        public var ordering = ""
        public var showCompleted = false

        init(key: Reminders.Filter.Key, ordering: String = "", showCompleted: Bool = false) {
            self.key = key
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Filter.Preference.Record {
    public init(key: Reminders.Filter.Key, _ preference: Reminders.Filter.Preference) {
        self.init(key: key, ordering: preference.ordering.rawValue, showCompleted: preference.showCompleted)
    }
}

extension Reminders.Filter.Preference.Record: Identifiable {
    public var id: Reminders.Filter.Key { key }
}

extension Reminders.Filter.Preference.Record {
    public static func preference(for filter: Reminders.Filter) -> Where<Reminders.Filter.Preference.Record> {
        Reminders.Filter.Preference.Record.find(Reminders.Filter.Key(filter))
    }

    public static func set(ordering: Reminders.Ordering, for filter: Reminders.Filter) -> InsertOf<Reminders.Filter.Preference.Record> {
        var preference = filter.defaultPreference
        preference.ordering = ordering
        return Reminders.Filter.Preference.Record.insert {
            Reminders.Filter.Preference.Record(key: Reminders.Filter.Key(filter), preference)
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    public static func toggleShowCompleted(for filter: Reminders.Filter) -> InsertOf<Reminders.Filter.Preference.Record> {
        var preference = filter.defaultPreference
        preference.showCompleted.toggle()
        return Reminders.Filter.Preference.Record.insert {
            Reminders.Filter.Preference.Record(key: Reminders.Filter.Key(filter), preference)
        } onConflict: {
            $0.key
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}
