public import Reminders
public import StructuredQueries
public import Tagged

extension Reminders {
    @Table("session")
    public struct Restoration: Hashable, Sendable {
        public let id: Int
        public var filter: Filter.Key?
        public var editing: Reminder.ID?

        public init(id: Int = 1, filter: Filter.Key? = nil, editing: Reminder.ID? = nil) {
            self.id = id
            self.filter = filter
            self.editing = editing
        }
    }
}

extension Reminders.Restoration {
    public static var current: Where<Reminders.Restoration> { Reminders.Restoration.find(1) }

    public static func set(filter: Reminders.Filter?) -> UpdateOf<Reminders.Restoration> {
        Reminders.Restoration.find(1).update { $0.filter = filter.map(Reminders.Filter.Key.init) }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Reminders.Restoration> {
        Reminders.Restoration.find(1).update { $0.editing = editing }
    }
}
