public import Organizing
public import Reminders
public import Tagged

extension Reminders.Filter.Detail {
    public struct Row: Identifiable, Hashable, Sendable {
        public var reminder: Reminder
        public var color: Color

        public var id: Reminder.ID { reminder.id }

        public init(reminder: Reminder, color: Color) {
            self.reminder = reminder
            self.color = color
        }
    }
}
