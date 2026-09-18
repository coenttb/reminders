public import Foundation
public import List
public import Reminder
public import StructuredQueries
public import Tagged

extension Reminder {
    @Table("reminders")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Reminder.ID
        public var listID: List<Reminder>.ID
        public var title: String = ""
        public var completed: Bool = false
        public var position: Int = 0
        public var created: Date

        public init(id: Reminder.ID, listID: List<Reminder>.ID, title: String = "", completed: Bool = false, position: Int = 0, created: Date) {
            self.id = id
            self.listID = listID
            self.title = title
            self.completed = completed
            self.position = position
            self.created = created
        }
    }
}

extension Reminder.Record.Draft: Hashable, Sendable {}

extension Reminder.Record.Draft {
    public init(_ reminder: Reminder, position: Int = 0) {
        self.init(id: reminder.id, listID: reminder.list, title: reminder.title, completed: reminder.completed, position: position, created: reminder.created)
    }
}

extension Reminder {
    public init(_ record: Reminder.Record) {
        self.init(id: record.id, list: record.listID, title: record.title, completed: record.completed, created: record.created)
    }
}
