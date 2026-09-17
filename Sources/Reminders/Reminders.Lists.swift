public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface {
        public protocol Interface {
            func create(_ list: Models.List<Reminder>) async throws
            func update(_ list: Models.List<Reminder>) async throws
            func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) async throws
            func reorder(_ ids: [Models.List<Reminder>.ID]) async throws
        }
    }
}

