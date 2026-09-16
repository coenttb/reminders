public import Reminder

extension Reminders {
    public struct Placement: Hashable, Sendable {
        public var reminder: Reminder
        public var position: Int

        public init(_ reminder: Reminder, position: Int) {
            self.reminder = reminder
            self.position = position
        }
    }
}
