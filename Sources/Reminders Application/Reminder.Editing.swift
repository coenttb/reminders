public import Foundation
public import Reminders

extension Reminder {
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder
        public var saved: Reminder
        public let place: Reminder
        public let session: UUID
        public var failure: String?

        public var id: Reminder.ID { saved.id }

        public var isSaved: Bool { draft == saved }

        public init(draft: Reminder, saved: Reminder, place: Reminder, session: UUID) {
            self.draft = draft
            self.saved = saved
            self.place = place
            self.session = session
        }

        public init(_ reminder: Reminder, session: UUID) {
            self.init(draft: reminder, saved: reminder, place: reminder, session: session)
        }
    }
}
