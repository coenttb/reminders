public import Foundation
public import Models
public import Tagged

public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: Models.List<Reminder>.ID
    public var title: String
    public var notes: String
    public var due: Due?
    public var repeats: Calendar.RecurrenceRule?
    public var priority: Priority?
    public var flagged: Bool
    // When the reminder was completed; nil while it is open.
    public var completed: Date?
    // When the reminder was deleted; it stays in Recently Deleted for thirty days, then goes for good.
    public var deleted: Date?
    public var tags: Set<Tag<Reminder>>
    public var created: Date

    public init(
        id: ID,
        list: Models.List<Reminder>.ID,
        title: String = "",
        notes: String = "",
        due: Due? = nil,
        repeats: Calendar.RecurrenceRule? = nil,
        priority: Priority? = nil,
        flagged: Bool = false,
        completed: Date? = nil,
        deleted: Date? = nil,
        tags: Set<Tag<Reminder>> = [],
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
        self.deleted = deleted
        self.tags = tags
        self.created = created
    }

    public var isCompleted: Bool { completed != nil }

    public var isDeleted: Bool { deleted != nil }

    // How long a deleted reminder is kept.
    public static let retention: TimeInterval = 30 * 24 * 60 * 60
}
