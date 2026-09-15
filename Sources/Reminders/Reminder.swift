public import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Tagged

/// One reminder: what to do, in which list, by when, how urgent, and its tags. The rules are
/// statics over a value; the instance members forward to them.
public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: List<Reminder>.ID
    public var title: String
    public var notes: String
    public var due: Due?
    public var flagged: Bool
    public var priority: Priority?
    public var completion: Completion
    public var tags: Set<Tag<Reminder>.ID>
    public var position: Int
    public var location: Location?
    public var repeats: Repeat

    public init(
        id: ID,
        list: List<Reminder>.ID,
        title: String = "",
        notes: String = "",
        due: Due? = nil,
        flagged: Bool = false,
        priority: Priority? = nil,
        completion: Completion = .incomplete,
        tags: Set<Tag<Reminder>.ID> = [],
        position: Int = 0,
        location: Location? = nil,
        repeats: Repeat = .never
    ) {
        self.id = id
        self.list = list
        self.title = title
        self.notes = notes
        self.due = due
        self.flagged = flagged
        self.priority = priority
        self.completion = completion
        self.tags = tags
        self.position = position
        self.location = location
        self.repeats = repeats
    }
}

extension Reminder {
    public static func completed(_ reminder: Self) -> Bool { reminder.completion == .completed }

    public var completed: Bool { Self.completed(self) }

    /// A title of only whitespace is no reminder.
    public static func isBlank(_ reminder: Self) -> Bool { reminder.title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(self) }

    /// Incomplete and due on a day before today.
    public static func pastDue(_ reminder: Self, at now: Date, calendar: Calendar) -> Bool {
        guard !reminder.completed, let due = reminder.due else { return false }
        return calendar.compare(due.date, to: now, toGranularity: .day) == .orderedAscending
    }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { Self.pastDue(self, at: now, calendar: calendar) }
}

extension Reminder {
    /// The circle tap flips the completion; the grace period around it is the application's.
    public static func toggling(_ reminder: Self) -> Self {
        var toggled = reminder
        toggled.completion = reminder.completed ? .incomplete : .completed
        return toggled
    }

    public mutating func toggle() { self = Self.toggling(self) }

    /// A new day keeps the time of day if one was set; none drops the date and the time with it.
    public static func setting(_ reminder: Self, due date: Date?) -> Self {
        var set = reminder
        set.due = date.map { Due($0, hasTime: reminder.due?.hasTime ?? false) }
        return set
    }

    public mutating func set(due date: Date?) { self = Self.setting(self, due: date) }

    /// Turning the time on proposes the next full hour, on the due day if there is one; turning
    /// it off keeps the day.
    public static func setting(_ reminder: Self, hasTime: Bool, at now: Date, calendar: Calendar) -> Self {
        var set = reminder
        let day = reminder.due?.date ?? now
        set.due = hasTime
            ? .moment(calendar.nextHour(after: now).flatMap { calendar.date(day: day, time: $0) } ?? day)
            : reminder.due.map { .day($0.date) }
        return set
    }

    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar) {
        self = Self.setting(self, hasTime: hasTime, at: now, calendar: calendar)
    }
}
