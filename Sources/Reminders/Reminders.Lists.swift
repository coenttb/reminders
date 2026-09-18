public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface {
        public protocol Interface {
            func create(_ list: Models.List<Reminder>) async throws
            // Deleting the last list installs the default one under the replacement id.
            func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) async throws
        }
    }
}
