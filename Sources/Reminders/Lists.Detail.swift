public import Foundation
public import Tagged

extension Lists {
    /// A screen of reminders: one of the smart groups, one list, or a set of tags.
    public enum Detail: Hashable, Sendable {
        case all
        case completed
        case flagged
        case list(Reminder.List.ID)
        case scheduled
        case tags([Tag.ID])
        case today
    }
}

extension Lists.Detail: Identifiable {
    public typealias ID = Tagged<Lists.Detail, String>

    /// Tag titles are free text, so the tag key joins them with the unit separator; the tags are
    /// sorted so the same set of tags shares one key whatever order it was opened in.
    private static let separator = "\u{1F}"

    /// A stable key, also the one preferences are stored under.
    public var id: ID {
        switch self {
        case .all: "all"
        case .completed: "completed"
        case .flagged: "flagged"
        case let .list(id): ID("list_\(id.rawValue.uuidString)")
        case .scheduled: "scheduled"
        case let .tags(tags): ID("tags_" + tags.sorted().map(\.rawValue).joined(separator: Self.separator))
        case .today: "today"
        }
    }

    public init?(id: ID) {
        switch id.rawValue {
        case "all": self = .all
        case "completed": self = .completed
        case "flagged": self = .flagged
        case "scheduled": self = .scheduled
        case "today": self = .today
        case let raw where raw.hasPrefix("list_"):
            guard let uuid = UUID(uuidString: String(raw.dropFirst(5))) else { return nil }
            self = .list(Reminder.List.ID(uuid))
        case let raw where raw.hasPrefix("tags_"):
            self = .tags(raw.dropFirst(5).split(separator: Self.separator).map { Tag.ID(String($0)) })
        default:
            return nil
        }
    }
}

extension Lists.Detail {
    /// How a detail sorts and whether it shows completed reminders; persisted per detail.
    public struct Preference: Hashable, Sendable {
        public var ordering: Lists.Ordering
        public var showCompleted: Bool

        public init(ordering: Lists.Ordering = .dueDate, showCompleted: Bool = false) {
            self.ordering = ordering
            self.showCompleted = showCompleted
        }
    }

    /// Completed shows completed reminders; every other detail hides them until asked.
    public var defaultPreference: Preference {
        Preference(showCompleted: self == .completed)
    }

    public var isList: Bool {
        if case .list = self { true } else { false }
    }
}

extension Lists {
    /// The raw value is the stored key; the name the menu shows is `title`.
    public enum Ordering: String, CaseIterable, Hashable, Sendable {
        case dueDate, manual, priority, title

        public var title: String {
            switch self {
            case .dueDate: "Due Date"
            case .manual: "Manual"
            case .priority: "Priority"
            case .title: "Title"
            }
        }
    }

    public func preference(for detail: Detail) -> Detail.Preference {
        preferences[detail.id] ?? detail.defaultPreference
    }

    public mutating func set(ordering: Ordering, for detail: Detail) {
        preferences[detail.id, default: detail.defaultPreference].ordering = ordering
    }

    public mutating func toggleShowCompleted(for detail: Detail) {
        preferences[detail.id, default: detail.defaultPreference].showCompleted.toggle()
    }

    /// The reminders a detail shows, filtered by its membership and its preference, ordered by its preference.
    public func reminders(in detail: Detail, at now: Date, calendar: Calendar = .current) -> [Reminder] {
        let preference = preference(for: detail)
        let members = reminders.filter { reminder in
            switch detail {
            case .all: true
            case .completed: reminder.completed
            case .flagged: reminder.flagged
            case let .list(id): reminder.list == id
            case .scheduled: reminder.scheduled
            case let .tags(tags): !reminder.tags.isDisjoint(with: tags)
            case .today: reminder.dueToday(at: now, calendar: calendar)
            }
        }
        // A reminder in its grace period stays on screen, in place, so the tap can be undone;
        // completed ones sort last only when the detail shows them.
        let shown = preference.showCompleted ? members : members.filter { $0.status != .completed }
        // The row being edited keeps its place until editing ends.
        func placed(_ reminder: Reminder) -> Reminder {
            reminder.id == editing ? editingPlace ?? reminder : reminder
        }
        return shown.sorted { lhs, rhs in
            let (l, r) = (placed(lhs), placed(rhs))
            if preference.showCompleted, l.completed != r.completed { return !l.completed }
            return Lists.precedes(l, r, by: preference.ordering)
        }
    }

    /// The name a detail shows.
    public func title(of detail: Detail) -> String {
        switch detail {
        case .all: "All"
        case .completed: "Completed"
        case .flagged: "Flagged"
        case let .list(id): list(id)?.title ?? ""
        case .scheduled: "Scheduled"
        case let .tags(tags): tags.count == 1 ? "#\(tags[0])" : tags.isEmpty ? "Tags" : "\(tags.count) tags"
        case .today: "Today"
        }
    }

    static func precedes(_ lhs: Reminder, _ rhs: Reminder, by ordering: Ordering) -> Bool {
        switch ordering {
        case .dueDate:
            switch (lhs.due, rhs.due) {
            case let (l?, r?): return l == r ? lhs.position < rhs.position : l < r
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return lhs.position < rhs.position
            }
        case .manual: return lhs.position < rhs.position
        case .priority:
            let l = (lhs.priority?.rawValue ?? 0, lhs.flagged ? 1 : 0)
            let r = (rhs.priority?.rawValue ?? 0, rhs.flagged ? 1 : 0)
            return l == r ? lhs.position < rhs.position : l > r
        case .title:
            switch lhs.title.localizedCaseInsensitiveCompare(rhs.title) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            case .orderedSame: return lhs.position < rhs.position
            }
        }
    }
}
