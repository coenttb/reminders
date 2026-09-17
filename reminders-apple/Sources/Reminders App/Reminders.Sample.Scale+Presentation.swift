#if DEBUG
import Reminders
import Reminders_Sample

extension Reminders.Sample.Scale {
    var title: String {
        let count = reminders >= 1_000 ? "\(reminders / 1_000)k" : "\(reminders)"
        switch self {
        case .medium: return "Medium (\(count))"
        case .large: return "Large (\(count))"
        case .extreme: return "Extreme (\(count))"
        default: return "\(lists) lists × \(remindersPerList) (\(count))"
        }
    }
}
#endif
