public import Foundation
public import Organizing
public import Reminders
public import Tagged

extension Reminders.Overview.View {
    public struct Actions {
        public var open: (Reminders.Filter) -> Void
        public var details: (List<Reminder>.ID) -> Void
        public var delete: (List<Reminder>.ID) -> Void
        public var move: (IndexSet, Int) -> Void
        public var deleteTag: (Tag<Reminder>.ID) -> Void

        public init(
            open: @escaping (Reminders.Filter) -> Void,
            details: @escaping (List<Reminder>.ID) -> Void,
            delete: @escaping (List<Reminder>.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag<Reminder>.ID) -> Void
        ) {
            self.open = open
            self.details = details
            self.delete = delete
            self.move = move
            self.deleteTag = deleteTag
        }
    }
}
