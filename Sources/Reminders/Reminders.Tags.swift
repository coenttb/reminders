public import Interface_Macro
public import Models
public import Reminder

extension Reminders {
    @Interface
    public struct Tags: Tags.Interface {
        public protocol Interface {
            func create(_ title: String) throws -> Tag<Reminder>
            func update(_ tag: Tag<Reminder>, title: String) throws -> Tag<Reminder>
            func delete(_ tag: Tag<Reminder>) throws
            func list(prefix: String, excluding: Set<Tag<Reminder>>) throws -> [Tag<Reminder>]
        }
    }
}

