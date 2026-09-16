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
}
