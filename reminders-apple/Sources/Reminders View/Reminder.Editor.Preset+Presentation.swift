public import Reminder
public import Reminders
public import Reminders_Feature

extension Reminder.Editor.Preset {
    public var title: String {
        switch self {
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        case .thisWeekend: "This Weekend"
        case .nextWeek: "Next Week"
        }
    }
}
