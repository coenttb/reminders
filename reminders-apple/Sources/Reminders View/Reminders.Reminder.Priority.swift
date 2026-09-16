public import Reminders

extension Reminders.Reminder.Priority {
    public var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    public var marks: String { String(repeating: "!", count: rawValue) }
}
