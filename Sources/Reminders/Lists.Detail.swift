import Foundation
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

    /// Tag titles are free text, so the tag key joins them with the unit separator; the tags are
    /// sorted so the same set of tags shares one key whatever order it was opened in.
    private static let separator = "\u{1F}"

    /// A stable key, also the one preferences are stored under.
    public var id: Tagged<Lists.Detail, String> {
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

    /// The name a detail shows; a list's is its title, read with the rest of its contents.
    public var title: String? {
        switch self {
        case .all: "All"
        case .completed: "Completed"
        case .flagged: "Flagged"
        case .list: nil
        case .scheduled: "Scheduled"
        case let .tags(tags): tags.count == 1 ? "#\(tags[0])" : tags.isEmpty ? "Tags" : "\(tags.count) tags"
        case .today: "Today"
        }
    }

    /// The detail without a tag that no longer exists: narrowed, or closed when it was the last one.
    public func removing(tag id: Tag.ID) -> Lists.Detail? {
        guard case let .tags(open) = self else { return self }
        return open == [id] ? nil : .tags(open.filter { $0 != id })
    }

    /// The detail without a list that no longer exists: closed when it was that list.
    public func removing(list id: Reminder.List.ID) -> Lists.Detail? {
        if case let .list(open) = self, open == id { nil } else { self }
    }
}

extension Lists.Detail {
    /// One detail as read from the database: its name, its list's color when it is a list,
    /// its preference, and the reminders it shows in the preference's order, each with the
    /// color of the list it belongs to.
    public struct Contents: Hashable, Sendable {
        public var title: String
        public var color: Reminder.List.Color?
        public var preference: Preference
        public var rows: [Row]

        public init(title: String = "", color: Reminder.List.Color? = nil, preference: Preference = Preference(), rows: [Row] = []) {
            self.title = title
            self.color = color
            self.preference = preference
            self.rows = rows
        }

        /// One reminder in a detail, tinted by its list.
        public struct Row: Identifiable, Hashable, Sendable {
            public var reminder: Reminder
            public var color: Reminder.List.Color

            public var id: Reminder.ID { reminder.id }

            public init(reminder: Reminder, color: Reminder.List.Color) {
                self.reminder = reminder
                self.color = color
            }
        }

        public var reminders: [Reminder] { rows.map(\.reminder) }
    }
}

extension Lists {
    /// The raw value is the stored key; the name the menu shows is `title`, in the stock menu's order.
    public enum Ordering: String, CaseIterable, Hashable, Sendable {
        case manual, dueDate, priority, title

        public var title: String {
            switch self {
            case .dueDate: "Due Date"
            case .manual: "Manual"
            case .priority: "Priority"
            case .title: "Title"
            }
        }
    }
}
