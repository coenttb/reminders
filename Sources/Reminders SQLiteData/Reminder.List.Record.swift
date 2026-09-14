public import Foundation
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder.List {
    /// The stored form of a list; the color is its `0xRRGGBB` integer.
    @Table("lists")
    public struct Record: Identifiable, Sendable {
        public let id: Reminder.List.ID
        public var title = ""
        public var color: Int64 = 0
        public var position = 0

        public init(_ list: Reminder.List) {
            id = list.id
            title = list.title
            color = list.color.hex
            position = list.position
        }
    }
}

extension Reminder.List.Record {
    public var list: Reminder.List {
        Reminder.List(id: id, title: title, color: Reminder.List.Color(hex: color), position: position)
    }
}
