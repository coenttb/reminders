public import Reminders
public import Reminders_Interface
public import StructuredQueries

extension Reminders.Filter.Preference.Record: Identifiable {
    public var id: Reminders.Filter.Key { key }
}
