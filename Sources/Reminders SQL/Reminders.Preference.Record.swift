public import Foundation
public import Reminders
public import StructuredQueries

extension Reminders.Preference {
    @Table("preferences")
    public struct Record: Hashable, Sendable {
        @Column(primaryKey: true)
        public var key: Reminders.Filter.Key
        @Column(as: Reminders.Ordering.Representation.self)
        public var ordering: Reminders.Ordering = .dueDate
        @Column(as: SortOrder.Representation.self)
        public var direction: SortOrder = .forward
        public var showCompleted = false

        public init(key: Reminders.Filter.Key, ordering: Reminders.Ordering = .dueDate, direction: SortOrder = .forward, showCompleted: Bool = false) {
            self.key = key
            self.ordering = ordering
            self.direction = direction
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Preference.Record: Identifiable {
    public var id: Reminders.Filter.Key { key }
}

extension Reminders.Preference {
    public init(_ record: Record) {
        self.init(ordering: record.ordering, direction: record.direction, showCompleted: record.showCompleted)
    }
}

extension Reminders.Preference.Record {
    public init(_ preference: Reminders.Preference, for filter: Reminders.Filter) {
        self.init(key: Reminders.Filter.Key(filter), ordering: preference.ordering, direction: preference.direction, showCompleted: preference.showCompleted)
    }
}
