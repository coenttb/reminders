public import Models
public import Reminder

extension Reminders {
    public enum Filter: Hashable, Sendable {
        case all
        case completed
        case flagged
        case scheduled
        case today
        case list(Models.List<Reminder>.ID)
        case tags(Set<Tag<Reminder>>)
        // The reminders deleted in the last thirty days: recoverable, or deleted for good.
        case recentlyDeleted

        // The smart lists that gather rows from every list show them list by list, as the stock app does.
        public var groupsByList: Bool {
            switch self {
            case .all, .flagged, .tags: true
            case .completed, .recentlyDeleted, .scheduled, .today, .list: false
            }
        }

        // Completed and Recently Deleted show completed rows from the start.
        public var showsCompleted: Bool {
            self == .completed || self == .recentlyDeleted
        }

        // Today and Scheduled section their rows by day and by time of day, as the stock app does.
        public var sectionsByDay: Bool {
            switch self {
            case .completed, .scheduled, .today: true
            case .all, .flagged, .list, .recentlyDeleted, .tags: false
            }
        }
    }
}
