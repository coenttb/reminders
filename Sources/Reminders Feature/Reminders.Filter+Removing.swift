public import Models
public import Reminder
public import Reminders

extension Reminders.Filter {
    public static func removing(_ filter: Self, tag id: Tag<Reminder>) -> Self? {
        guard case let .tags(open) = filter else { return filter }
        return open == [id] ? nil : .tags(open.subtracting([id]))
    }

    public func removing(tag id: Tag<Reminder>) -> Self? { Self.removing(self, tag: id) }

    public static func removing(_ filter: Self, list id: List<Reminder>.ID) -> Self? {
        if case let .list(open) = filter, open == id { nil } else { filter }
    }

    public func removing(list id: List<Reminder>.ID) -> Self? { Self.removing(self, list: id) }
}
