public import Models
public import Reminder

extension Reminders.Tags {
    public struct Client: Sendable {
        public var add: @Sendable (_ title: String) throws -> Tag<Reminder>?
        public var rename: @Sendable (Tag<Reminder>, _ title: String) throws -> Tag<Reminder>?
        public var delete: @Sendable (Tag<Reminder>) throws -> Void
        public var suggest: @Sendable (Suggestions) throws -> [Tag<Reminder>]

        public init(
            add: @escaping @Sendable (_ title: String) throws -> Tag<Reminder>?,
            rename: @escaping @Sendable (Tag<Reminder>, _ title: String) throws -> Tag<Reminder>?,
            delete: @escaping @Sendable (Tag<Reminder>) throws -> Void,
            suggest: @escaping @Sendable (Suggestions) throws -> [Tag<Reminder>]
        ) {
            self.add = add
            self.rename = rename
            self.delete = delete
            self.suggest = suggest
        }
    }
}
