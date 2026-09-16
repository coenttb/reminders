public import Organizing
public import Reminder
public import Tagged

extension Reminders {
    public enum Filter: Hashable, Sendable {
        case all
        case completed
        case flagged
        case scheduled
        case today
        case list(List<Reminder>.ID)
        case tags(Set<Tag<Reminder>.ID>)
    }
}

extension Reminders.Filter {
    public static func removing(_ filter: Self, tag id: Tag<Reminder>.ID) -> Self? {
        guard case let .tags(open) = filter else { return filter }
        return open == [id] ? nil : .tags(open.subtracting([id]))
    }

    public func removing(tag id: Tag<Reminder>.ID) -> Self? { Self.removing(self, tag: id) }

    public static func removing(_ filter: Self, list id: List<Reminder>.ID) -> Self? {
        if case let .list(open) = filter, open == id { nil } else { filter }
    }

    public func removing(list id: List<Reminder>.ID) -> Self? { Self.removing(self, list: id) }
}
