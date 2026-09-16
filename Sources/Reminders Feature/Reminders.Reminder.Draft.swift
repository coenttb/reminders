public import Foundation
public import Reminders

extension Reminders.Reminder {
    public struct Draft: Hashable, Sendable {
        public var reminder: Reminder
        public let original: Reminder
        public let isNew: Bool
        public let session: UUID

        public init(_ reminder: Reminder, isNew: Bool, session: UUID) {
            self.reminder = reminder
            self.original = reminder
            self.isNew = isNew
            self.session = session
        }

        public var isDirty: Bool { reminder != original }
    }
}
