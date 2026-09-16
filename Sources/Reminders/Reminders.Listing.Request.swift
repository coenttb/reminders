public import Foundation

extension Reminders.Listing {
    public struct Request: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var today: Range<Date>
        public var place: Reminders.Placement?
        public var limit: Int?

        public init(selection: Reminders.Selection, today: Range<Date>, place: Reminders.Placement? = nil, limit: Int? = nil) {
            self.selection = selection
            self.today = today
            self.place = place
            self.limit = limit
        }
    }
}
