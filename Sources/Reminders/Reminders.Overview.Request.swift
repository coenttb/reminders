public import Foundation

extension Reminders.Overview {
    public struct Request: Hashable, Sendable {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }
    }
}
