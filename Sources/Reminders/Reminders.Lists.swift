public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface {
        @Operations
        public protocol Interface {
            func create(_ draft: Models.List<Reminder>.Draft) async throws -> Models.List<Reminder>
            // There is always a list: deleting the last one installs the default list.
            func delete(_ id: Models.List<Reminder>.ID) async throws
        }
    }
}
