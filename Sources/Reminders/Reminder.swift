public import Foundation
public import Tagged

/// One reminder: what to do, in which list, by when, how urgent, and its tags.
public struct Reminder: Identifiable, Hashable, Sendable {
    public typealias ID = Tagged<Reminder, UUID>

    public var id: ID
    public var list: List.ID
    public var title: String
    public var notes: String
    public var due: Date?
    public var flagged: Bool
    public var priority: Priority?
    public var status: Status
    public var tags: Set<Tag.ID>
    public var position: Int

    public init(
        id: ID,
        list: List.ID,
        title: String = "",
        notes: String = "",
        due: Date? = nil,
        flagged: Bool = false,
        priority: Priority? = nil,
        status: Status = .incomplete,
        tags: Set<Tag.ID> = [],
        position: Int = 0
    ) {
        self.id = id
        self.list = list
        self.title = title
        self.notes = notes
        self.due = due
        self.flagged = flagged
        self.priority = priority
        self.status = status
        self.tags = tags
        self.position = position
    }
}

extension Reminder {
    public enum Priority: Int, CaseIterable, Hashable, Sendable {
        case low = 1
        case medium
        case high
    }

    /// Completing is the grace period after tapping the circle, during which the tap can be undone.
    public enum Status: Int, Hashable, Sendable {
        case incomplete = 0
        case completed
        case completing
    }
}

extension Reminder {
    /// Completing counts as completed everywhere but the grace timer.
    public var completed: Bool { status != .incomplete }

    public var scheduled: Bool { !completed && due != nil }

    /// Tags in a stable, display order.
    public var sortedTags: [Tag.ID] { tags.sorted() }

    /// Incomplete and due on a day before today.
    public func pastDue(at now: Date) -> Bool {
        guard !completed, let due else { return false }
        return Calendar.current.startOfDay(for: due) < Calendar.current.startOfDay(for: now)
    }

    /// Incomplete and due today.
    public func dueToday(at now: Date) -> Bool {
        guard !completed, let due else { return false }
        return Calendar.current.isDate(due, inSameDayAs: now)
    }

    /// The circle tap: incomplete starts completing; completing or completed reverts to incomplete.
    public mutating func toggle() {
        status = status == .incomplete ? .completing : .incomplete
    }

    /// The grace timer elapsed.
    public mutating func complete() {
        if status == .completing { status = .completed }
    }

    /// Whether the text, title, notes, or tags contain the query, case-insensitively.
    public func matches(_ text: String) -> Bool {
        title.localizedCaseInsensitiveContains(text)
            || notes.localizedCaseInsensitiveContains(text)
            || tags.contains { $0.rawValue.localizedCaseInsensitiveContains(text) }
    }
}
