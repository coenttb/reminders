public import Foundation
public import Reminders

extension Reminders.Ordering {
    public var title: String {
        switch self {
        case .dueDate: "Deadline"
        case .creationDate: "Creation Date"
        case .manual: "Manual"
        case .priority: "Priority"
        case .title: "Title"
        }
    }

    // What a direction is called depends on the key: the manual order has none.
    public func title(_ direction: SortOrder) -> String? {
        switch (self, direction) {
        case (.manual, _): nil
        case (.dueDate, .forward): "Earliest First"
        case (.dueDate, .reverse): "Latest First"
        case (.creationDate, .forward): "Oldest First"
        case (.creationDate, .reverse): "Newest First"
        case (.priority, .forward): "Highest First"
        case (.priority, .reverse): "Lowest First"
        case (.title, .forward): "Ascending"
        case (.title, .reverse): "Descending"
        }
    }
}
