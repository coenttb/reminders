public import Foundation
public import Models

extension Reminders.Editor.Client {
    public struct DeleteCompleted: Models.Operation {
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Editor.Client.DeleteCompleted {
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
