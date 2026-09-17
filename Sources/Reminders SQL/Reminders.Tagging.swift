public import Models
public import Reminder
public import Reminders
public import StructuredQueries
public import Tagged

extension Reminders {
    @Table("remindersTags")
    public struct Tagging: Sendable {
        public var reminderID: Reminder.ID
        public var tagID: Tag<Reminder>

        public init(reminderID: Reminder.ID, tagID: Tag<Reminder>) {
            self.reminderID = reminderID
            self.tagID = tagID
        }
    }
}
