public import Reminders
public import StructuredQueries

extension Reminders.Filter {
    @Table("preferences")
    public struct Preference: Hashable, Sendable {
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

extension Reminders.Filter.Preference {
    public static func `default`(for filter: Reminders.Filter) -> Self {
        Self(key: Reminders.Filter.Key(filter), showCompleted: filter == .completed)
    }

    public static func preference(for filter: Reminders.Filter) -> Where<Reminders.Filter.Preference> {
        Reminders.Filter.Preference.find(Reminders.Filter.Key(filter))
    }

    public static func set(ordering: Reminders.Ordering, for filter: Reminders.Filter) -> InsertOf<Reminders.Filter.Preference> {
        var preference = Self.default(for: filter)
        preference.ordering = ordering
        return Reminders.Filter.Preference.insert {
            preference
        } onConflict: {
            $0.key
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    public static func toggleShowCompleted(for filter: Reminders.Filter) -> InsertOf<Reminders.Filter.Preference> {
        var preference = Self.default(for: filter)
        preference.showCompleted.toggle()
        return Reminders.Filter.Preference.insert {
            preference
        } onConflict: {
            $0.key
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}
