public import Reminder
public import Tagged

extension Reminder {
    public enum Row {
        public struct Actions {
            public var complete: (Reminder.ID) -> Void
            public var delete: (Reminder.ID) -> Void
            public var details: (Reminder.ID) -> Void
            public var edit: ((Reminder.ID) -> Void)?

            public init(
                complete: @escaping (Reminder.ID) -> Void,
                delete: @escaping (Reminder.ID) -> Void,
                details: @escaping (Reminder.ID) -> Void,
                edit: ((Reminder.ID) -> Void)? = nil
            ) {
                self.complete = complete
                self.delete = delete
                self.details = details
                self.edit = edit
            }
        }
    }
}
