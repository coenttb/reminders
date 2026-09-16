public import Models
public import Reminder
public import Reminders
public import StructuredQueries
public import Tagged

extension Reminders {
    @Table("remindersTags")
    public struct Tagging: Sendable {
        public var reminderID: Reminder.ID
        public var tagID: Tag<Reminder>.ID

        public init(reminderID: Reminder.ID, tagID: Tag<Reminder>.ID) {
            self.reminderID = reminderID
            self.tagID = tagID
        }
    }
}

extension Reminders.Tagging {
    public static func detach(_ tags: Set<Tag<Reminder>.ID>, from id: Reminder.ID) -> DeleteOf<Reminders.Tagging> {
        Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.delete()
    }
}
