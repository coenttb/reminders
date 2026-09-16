public import Foundation
public import Models
public import Tagged

public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: List<Reminder>.ID
    public var title: String
    public var notes: String
    public var due: Due?
    public var repeats: Calendar.RecurrenceRule?
    public var priority: Priority?
    public var flagged: Bool
    public var completed: Bool
    public var tags: Set<Tag<Reminder>.ID>
    public var created: Date

    public init(
        id: ID,
        list: List<Reminder>.ID,
        title: String = "",
        notes: String = "",
        due: Due? = nil,
        repeats: Calendar.RecurrenceRule? = nil,
        priority: Priority? = nil,
        flagged: Bool = false,
        completed: Bool = false,
        tags: Set<Tag<Reminder>.ID> = [],
        created: Date
    ) {
        self.id = id
        self.list = list
        self.title = title
        self.notes = notes
        self.due = due
        self.repeats = repeats
        self.priority = priority
        self.flagged = flagged
        self.completed = completed
        self.tags = tags
        self.created = created
    }
}
