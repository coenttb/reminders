public import Foundation
public import Organizing
public import Tagged

extension Reminder {
    /// A screen of reminders: one of the smart groups, one list, or a set of tags.
    public enum Filter: Hashable, Sendable {
        case all
        case completed
        case flagged
        case scheduled
        case today
        case list(List<Reminder>.ID)
        case tags([Tag<Reminder>.ID])
    }
}

extension Reminder.Filter {
    /// Whether a reminder belongs to the filter; `today` is the day the filter of that name
    /// shows. Flagged shows flagged reminders whatever their completion; the other smart
    /// groups show open ones, and a tag filter any reminder carrying one of its tags.
    public static func contains(_ reminder: Reminder, in filter: Self, today: Range<Date>) -> Bool {
        switch filter {
        case .all: true
        case .completed: reminder.completed
        case .flagged: reminder.flagged
        case .scheduled: !reminder.completed && reminder.due != nil
        case .today: !reminder.completed && reminder.due.map { today.contains($0.date) } == true
        case let .list(id): reminder.list == id
        case let .tags(tags): !reminder.tags.isDisjoint(with: tags)
        }
    }

    public func contains(_ reminder: Reminder, today: Range<Date>) -> Bool {
        Self.contains(reminder, in: self, today: today)
    }

    public var isList: Bool {
        if case .list = self { true } else { false }
    }

    /// The filter without a tag that no longer exists: narrowed, or closed when it was the last one.
    public static func removing(_ filter: Self, tag id: Tag<Reminder>.ID) -> Self? {
        guard case let .tags(open) = filter else { return filter }
        return open == [id] ? nil : .tags(open.filter { $0 != id })
    }

    public func removing(tag id: Tag<Reminder>.ID) -> Self? { Self.removing(self, tag: id) }

    /// The filter without a list that no longer exists: closed when it was that list.
    public static func removing(_ filter: Self, list id: List<Reminder>.ID) -> Self? {
        if case let .list(open) = filter, open == id { nil } else { filter }
    }

    public func removing(list id: List<Reminder>.ID) -> Self? { Self.removing(self, list: id) }
}
