public import Reminders
public import StructuredQueries

extension Reminders.Preference {
    @Table("preferences")
    public struct Record: Hashable, Sendable {
        @Column(primaryKey: true)
        public var key: Reminders.Filter.Key
        @Column(as: Reminders.Ordering.Representation.self)
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
}
