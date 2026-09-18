public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface {
        @Operations
        public protocol Interface {
            func create(_ list: Models.List<Reminder>) async throws
            // There is always a list: deleting the last one installs the default list.
            func delete(_ id: Models.List<Reminder>.ID) async throws
        }
    }
}
