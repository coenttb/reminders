public import Reminders

extension Reminders.Summary.Counts {
    public subscript(_ filter: Reminders.Filter) -> Int? {
        switch filter {
        case .all: all
        case .flagged: flagged
        case .scheduled: scheduled
        case .today: today
        case .completed, .list, .tags: nil
        }
    }
}
