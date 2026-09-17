public import Models
public import Interface_Macro
public import Reminder

extension Reminders {
    @Interface
    public struct Lists: Sendable {
        public protocol `Protocol` {
            func create(_ list: Models.List<Reminder>) throws(any Swift.Error)
            func update(_ list: Models.List<Reminder>) throws(any Swift.Error)
            func delete(_ id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) throws(any Swift.Error)
            func reorder(_ ids: [Models.List<Reminder>.ID]) throws(any Swift.Error)
        }

        // generated / required by interface protocol
        var product: Lists.Product
        // any other generated types we can safely add here or compute / get for free
    }
}

