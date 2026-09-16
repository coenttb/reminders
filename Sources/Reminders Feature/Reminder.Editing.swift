public import Foundation
public import Reminder
public import Reminders

extension Reminder {
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder
        public var original: Reminder
        public let place: Reminders.Placement
        public let session: UUID
        public var failure: String?

        public init(draft: Reminder, original: Reminder, place: Reminders.Placement, session: UUID) {
            self.draft = draft
            self.original = original
            self.place = place
            self.session = session
        }

        public init(_ placement: Reminders.Placement, session: UUID) {
            self.init(draft: placement.reminder, original: placement.reminder, place: placement, session: session)
        }
    }
}

extension Reminder.Editing {
    public var id: Reminder.ID { original.id }

    public var isSaved: Bool { draft == original }
}
