public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Tags: Tags.`Protocol` {
        public protocol `Protocol` {
            func create(_ title: String) throws -> Tag<Reminder>
            func update(_ request: Update.Request) throws -> Tag<Reminder>
            func delete(_ tag: Tag<Reminder>) throws
            func list(_ request: List.Request) throws -> [Tag<Reminder>]
        }
    }
}

extension Reminders.Tags: @unchecked Sendable {}
