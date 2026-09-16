public import Reminders

extension Reminders.Editor.Preset {
    public var title: String {
        switch self {
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        case .thisWeekend: "This Weekend"
        case .nextWeek: "Next Week"
        }
    }
}
