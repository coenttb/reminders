public import Foundation
public import Reminders
public import Reminders_SQL

extension Reminders.Reminder {
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder.Record.Draft
        public var original: Reminder.Record
        public let place: Reminder
        public let session: UUID
        public var failure: String?

        public init(draft: Reminder.Record.Draft, original: Reminder.Record, place: Reminder, session: UUID) {
            self.draft = draft
            self.original = original
            self.place = place
            self.session = session
        }

        public init(_ row: Reminder.Record.Row, session: UUID) {
            self.init(draft: Reminder.Record.Draft(row.reminder), original: row.reminder, place: Reminder(row), session: session)
        }
    }
}

extension Reminders.Reminder.Editing {
    public var id: Reminder.ID { original.id }

    public var isSaved: Bool { draft == Reminder.Record.Draft(original) }
}
