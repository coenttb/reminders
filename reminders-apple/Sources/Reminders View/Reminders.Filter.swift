public import Organizing
public import Reminders
public import SwiftUI
import Tagged

extension Reminders.Filter {
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

extension Reminders.Filter {
    public func color(list: Organizing.Color?) -> SwiftUI.Color {
        switch self {
        case .all: .primary
        case .completed: .gray
        case .flagged: .orange
        case .list: list.map { SwiftUI.Color($0) } ?? .blue
        case .scheduled: .red
        case .tags, .today: .blue
        }
    }
}

extension Reminders.Filter {
    public static func smart(flagged: Bool) -> [Reminders.Filter] {
        flagged ? [.today, .scheduled, .all, .flagged, .completed] : [.today, .scheduled, .all, .completed]
    }
}
