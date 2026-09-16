public import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Tagged

extension Reminders {
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
        public var created: Date

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
            repeats: Repeat = .never,
            created: Date = .distantPast
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
            self.created = created
        }
    }
}

public typealias Reminder = Reminders.Reminder

extension Reminders.Reminder {
    public static func completed(_ reminder: Self) -> Bool { reminder.completion == .completed }

    public var completed: Bool { Self.completed(self) }

    public static func isBlank(_ reminder: Self) -> Bool { reminder.title.trimmed.isEmpty }

    public var isBlank: Bool { Self.isBlank(self) }

    public static func pastDue(_ reminder: Self, at now: Date, calendar: Calendar) -> Bool {
        guard !reminder.completed, let due = reminder.due else { return false }
        return calendar.compare(due.date, to: now, toGranularity: .day) == .orderedAscending
    }

    public func pastDue(at now: Date, calendar: Calendar) -> Bool { Self.pastDue(self, at: now, calendar: calendar) }
}

extension Reminders.Reminder {
    public static func toggling(_ reminder: Self) -> Self {
        var toggled = reminder
        toggled.completion = reminder.completed ? .incomplete : .completed
        return toggled
    }

    public mutating func toggle() { self = Self.toggling(self) }

    public static func setting(_ reminder: Self, due date: Date?) -> Self {
        var set = reminder
        set.due = date.map { Due($0, hasTime: reminder.due?.hasTime ?? false) }
        return set
    }

    public mutating func set(due date: Date?) { self = Self.setting(self, due: date) }

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
