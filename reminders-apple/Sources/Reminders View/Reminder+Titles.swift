import Organizing
public import Reminders
import Standard_Library_Extensions
import Tagged

// The names the screens show for the domain's values live here, not in the domain: a
// platform that words them differently maps the same values.

extension Reminder {
    /// The tags as one line of hashtags, in a stable order; empty for none.
    public var tagLine: String { tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ") }
}

extension Reminder.Priority {
    public var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    /// The exclamation marks a row shows before the title.
    public var marks: String { String(repeating: "!", count: rawValue) }
}

extension Reminder.Repeat {
    public var title: String { rawValue.uppercasingFirst }
}

extension Reminder.Location {
    public var title: String {
        switch self {
        case .gettingInCar: "Getting in Car"
        case .gettingOutOfCar: "Getting out of Car"
        }
    }
}

extension Reminder.Ordering {
    /// The name the sort menu shows, in the stock menu's order.
    public var title: String {
        switch self {
        case .dueDate: "Deadline"
        case .manual: "Manual"
        case .priority: "Priority"
        case .title: "Title"
        }
    }
}

extension Reminder.Filter {
    /// The name a filter shows; a list's is its title, read with the rest of its detail.
    public var title: String? {
        switch self {
        case .all: "All"
        case .completed: "Completed"
        case .flagged: "Flagged"
        case .list: nil
        case .scheduled: "Scheduled"
        case let .tags(tags): tags.count == 1 ? Tag<Reminder>.hashtag(tags[0]) : tags.isEmpty ? "Tags" : "\(tags.count) tags"
        case .today: "Today"
        }
    }
}
