public import Reminders
public import StructuredQueries

extension Reminders.Preference {
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

extension Reminders.Preference.Record: Identifiable {
    public var id: Reminders.Filter.Key { key }
}

extension Reminders.Preference {
    public init(_ record: Record) {
        self.init(ordering: record.ordering, showCompleted: record.showCompleted)
    }
}

extension Reminders.Preference.Record {
    public init(_ preference: Reminders.Preference, for filter: Reminders.Filter) {
        self.init(key: Reminders.Filter.Key(filter), ordering: preference.ordering, showCompleted: preference.showCompleted)
    }

    public static func `default`(for filter: Reminders.Filter) -> Self {
        Self(Reminders.Preference.default(for: filter), for: filter)
    }

    public static func preference(for filter: Reminders.Filter) -> Where<Self> {
        Self.find(Reminders.Filter.Key(filter))
    }

    public static func set(_ preference: Reminders.Preference, for filter: Reminders.Filter) -> InsertOf<Self> {
        Self.insert {
            Self(preference, for: filter)
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
            row.showCompleted = excluded.showCompleted
        }
    }

    public static func set(ordering: Reminders.Ordering, for filter: Reminders.Filter) -> InsertOf<Self> {
        var record = Self.default(for: filter)
        record.ordering = ordering
        return Self.insert {
            record
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    public static func toggleShowCompleted(for filter: Reminders.Filter) -> InsertOf<Self> {
        var record = Self.default(for: filter)
        record.showCompleted.toggle()
        return Self.insert {
            record
        } onConflict: {
            $0.key
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}
