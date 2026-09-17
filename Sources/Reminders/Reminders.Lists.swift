public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Reminders.Lists.`Protocol` {
        public protocol `Protocol` {
            func create(_ list: Models.List<Reminder>) throws
            func update(_ list: Models.List<Reminder>) throws
            func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) throws
            func reorder(_ ids: [Models.List<Reminder>.ID]) throws
        }
    }
}

extension Reminders.Lists: @unchecked Sendable {}
