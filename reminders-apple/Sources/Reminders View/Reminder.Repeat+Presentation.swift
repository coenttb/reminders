public import Reminder
import Standard_Library_Extensions

extension Reminder.Repeat {
    public var title: String { rawValue.uppercasingFirst }
}
