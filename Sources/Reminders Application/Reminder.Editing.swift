public import Foundation
public import Reminders

extension Reminder {
    /// One reminder edited in place: the draft the row's fields bind to, the value the database
    /// holds as far as this session has written it, so the commit is only what changed since,
    /// and the value the row is sorted by until editing ends, so it keeps its place under any
    /// ordering. The session tells one editing of a row from a later one: a write started for
    /// a session that has ended reports to nobody.
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder
        public var saved: Reminder
        public let place: Reminder
        public let session: UUID
        /// Why the draft could not be written when editing ended; the draft stays, and Done tries again.
        public var failure: String?

        public var id: Reminder.ID { saved.id }

        /// Whether the database holds the draft as typed.
        public var isSaved: Bool { draft == saved }

        public init(draft: Reminder, saved: Reminder, place: Reminder, session: UUID) {
            self.draft = draft
            self.saved = saved
            self.place = place
            self.session = session
        }

        /// Editing a stored reminder: the draft starts as, and sorts as, the stored value.
        public init(_ reminder: Reminder, session: UUID) {
            self.init(draft: reminder, saved: reminder, place: reminder, session: session)
        }
    }
}
