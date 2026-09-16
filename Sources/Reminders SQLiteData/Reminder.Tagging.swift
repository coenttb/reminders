public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder {
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
