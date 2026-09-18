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

        // The smart lists that gather rows from every list show them list by list, as the stock app does.
        public var groupsByList: Bool {
            switch self {
            case .all, .flagged, .tags: true
            case .completed, .scheduled, .today, .list: false
            }
        }

        // Today and Scheduled section their rows by day and by time of day, as the stock app does.
        public var sectionsByDay: Bool {
            switch self {
            case .scheduled, .today: true
            case .all, .completed, .flagged, .list, .tags: false
            }
        }
    }
}
