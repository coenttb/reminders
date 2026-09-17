public import Interface_Macro
public import Models

extension Reminders {
    @Interface
    public struct Preferences: Preferences.Interface {
        public protocol Interface {
            func update(_ filter: Reminders.Filter, change: Reminders.Preference.Change) throws
        }
    }
}

extension Reminders.Preferences: @unchecked Sendable {}
