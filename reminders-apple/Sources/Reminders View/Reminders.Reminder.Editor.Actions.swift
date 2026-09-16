public import Reminders
public import Reminders_Interface

extension Reminders.Reminder.Editor {
    public struct Actions {
        public var complete: (Reminder.ID) -> Void
        public var details: (Reminder.ID) -> Void
        public var submit: () -> Void
        public var setDate: (Reminder.ID, Reminders.Reminder.Due.Preset?) -> Void
        public var setTime: (Reminder.ID, Reminders.Reminder.Due.Preset.Time?) -> Void

        public init(
            complete: @escaping (Reminder.ID) -> Void,
            details: @escaping (Reminder.ID) -> Void,
            submit: @escaping () -> Void,
            setDate: @escaping (Reminder.ID, Reminders.Reminder.Due.Preset?) -> Void,
            setTime: @escaping (Reminder.ID, Reminders.Reminder.Due.Preset.Time?) -> Void
        ) {
            self.complete = complete
            self.details = details
            self.submit = submit
            self.setDate = setDate
            self.setTime = setTime
        }
    }
}
