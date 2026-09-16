public import Organizing
public import Reminders
public import Reminders_Interface
public import StructuredQueries

extension Reminders.Overview.Request {
    @Selection
    public struct Counts {
        public let all: Int
        public let flagged: Int
        public let scheduled: Int
        public let today: Int
    }
}
