public import Reminders

extension Reminders.Filter {
    public var defaultPreference: Preference { Preference.default(for: self) }
}
