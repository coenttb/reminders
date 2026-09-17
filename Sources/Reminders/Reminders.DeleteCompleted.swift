public import Foundation
public import Models

extension Reminders {
    public struct DeleteCompleted: Sendable {
        public typealias Result = Void
        public typealias Client = Models.Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.DeleteCompleted {
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
