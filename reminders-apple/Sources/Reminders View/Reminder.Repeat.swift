public import Reminders
import Standard_Library_Extensions

extension Reminder.Repeat {
    public var title: String { rawValue.uppercasingFirst }
}
