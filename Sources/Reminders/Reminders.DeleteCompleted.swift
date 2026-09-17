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
    public enum Request: Hashable, Sendable {
        case filter(Reminders.Filter, today: Range<Date>)
        case search(Reminders.Search.Query, dueBefore: Date?)
    }
}
