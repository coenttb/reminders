public import Models
public import Reminder

extension Reminder.Form {
    public struct Actions {
        public var save: () -> Void
        public var cancel: () -> Void
        public var tags: Tag<Reminder>.Picker.Actions

        public init(save: @escaping () -> Void, cancel: @escaping () -> Void, tags: Tag<Reminder>.Picker.Actions) {
            self.save = save
            self.cancel = cancel
            self.tags = tags
        }
    }
}
