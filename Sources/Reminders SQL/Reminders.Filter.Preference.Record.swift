public import Reminders
public import StructuredQueries

extension Reminders.Filter.Preference {
    @Table("preferences")
    public struct Record: Hashable, Sendable {
        @Column(primaryKey: true)
        public var key: Reminders.Filter.Key
        @Column(as: Reminders.Ordering.RawRepresentation.self)
        public var ordering: Reminders.Ordering = .dueDate
        public var showCompleted = false

        public init(key: Reminders.Filter.Key, ordering: Reminders.Ordering = .dueDate, showCompleted: Bool = false) {
            self.key = key
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Filter.Preference.Record: Identifiable {
    public var id: Reminders.Filter.Key { key }
}

extension Reminders.Filter.Preference {
    public init(_ record: Record) {
        self.init(ordering: record.ordering, showCompleted: record.showCompleted)
    }
}

extension Reminders.Filter.Preference.Record {
    public static func `default`(for filter: Reminders.Filter) -> Self {
        let preference = Reminders.Filter.Preference.default(for: filter)
        return Self(key: Reminders.Filter.Key(filter), ordering: preference.ordering, showCompleted: preference.showCompleted)
    }

    public static func preference(for filter: Reminders.Filter) -> Where<Self> {
        Self.find(Reminders.Filter.Key(filter))
    }

    public static func set(ordering: Reminders.Ordering, for filter: Reminders.Filter) -> InsertOf<Self> {
        var preference = Self.default(for: filter)
        preference.ordering = ordering
        return Self.insert {
            preference
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    public static func toggleShowCompleted(for filter: Reminders.Filter) -> InsertOf<Self> {
        var preference = Self.default(for: filter)
        preference.showCompleted.toggle()
        return Self.insert {
            preference
        } onConflict: {
            $0.key
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}
