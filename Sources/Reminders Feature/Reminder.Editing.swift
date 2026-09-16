public import Foundation
public import Reminder
public import Reminders
public import Reminders_SQL

extension Reminder {
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder.Record.Draft
        public var original: Reminder.Record
        public let place: Reminders.Filter.Detail.Placement
        public let session: UUID
        public var failure: String?

        public init(draft: Reminder.Record.Draft, original: Reminder.Record, place: Reminders.Filter.Detail.Placement, session: UUID) {
            self.draft = draft
            self.original = original
            self.place = place
            self.session = session
        }

        public init(_ row: Reminder.Record.Row, session: UUID) {
            self.init(
                draft: Reminder.Record.Draft(row.reminder),
                original: row.reminder,
                place: Reminders.Filter.Detail.Placement(Reminder(row), position: row.reminder.position),
                session: session
            )
        }
    }
}

extension Reminder.Editing {
    public var id: Reminder.ID { original.id }

    public var isSaved: Bool { draft == Reminder.Record.Draft(original) }
}
