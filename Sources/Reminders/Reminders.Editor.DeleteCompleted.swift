public import Foundation
public import Models

extension Reminders.Editor {
    public enum DeleteCompleted {
        public typealias Result = Void
        public typealias Client = Models.Operation<Request, Result>
    }
}

extension Reminders.Editor.DeleteCompleted {
    public struct Request: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var today: Range<Date>
        public var dueBefore: Date?

        public init(selection: Reminders.Selection, today: Range<Date>, dueBefore: Date? = nil) {
            self.selection = selection
            self.today = today
            self.dueBefore = dueBefore
        }
    }
}
