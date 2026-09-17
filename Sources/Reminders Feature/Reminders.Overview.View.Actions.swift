public import Reminders
public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders.Overview.View {
    public struct Actions {
        public var open: (Reminders.Filter) -> Void
        public var details: (Models.List<Reminder>.ID) -> Void
        public var delete: (Models.List<Reminder>.ID) -> Void
        public var move: (IndexSet, Int) -> Void
        public var deleteTag: (Tag<Reminder>) -> Void

        public init(
            open: @escaping (Reminders.Filter) -> Void,
            details: @escaping (Models.List<Reminder>.ID) -> Void,
            delete: @escaping (Models.List<Reminder>.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag<Reminder>) -> Void
        ) {
            self.open = open
            self.details = details
            self.delete = delete
            self.move = move
            self.deleteTag = deleteTag
        }
    }
}
