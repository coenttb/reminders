public import Foundation

extension Reminders {
    public struct Day: Hashable, Sendable {
        public var range: Range<Date>

        public init(_ range: Range<Date>) {
            self.range = range
        }
    }
}
