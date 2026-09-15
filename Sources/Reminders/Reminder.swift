public import Foundation
public import Tagged

/// One reminder: what to do, in which list, by when, how urgent, and its tags.
public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: List.ID
    public var title: String
    public var notes: String
    public var due: Date?
    /// Whether the due date's time of day matters; without it the reminder is due some time that day.
    public var hasTime: Bool
    public var flagged: Bool
    public var priority: Priority?
    public var status: Status
    public var tags: Set<Tag.ID>
    public var position: Int
    public var location: Location?
    public var repeats: Repeat

    public init(
        id: ID,
        list: List.ID,
        title: String = "",
        notes: String = "",
        due: Date? = nil,
        hasTime: Bool = false,
        flagged: Bool = false,
        priority: Priority? = nil,
        status: Status = .incomplete,
        tags: Set<Tag.ID> = [],
        position: Int = 0,
        location: Location? = nil,
        repeats: Repeat = .never
    ) {
        self.id = id
        self.list = list
        self.title = title
        self.notes = notes
        self.due = due
        self.hasTime = hasTime
        self.flagged = flagged
        self.priority = priority
        self.status = status
        self.tags = tags
        self.position = position
        self.location = location
        self.repeats = repeats
    }
}

extension Reminder {
    /// The two fixed locations the inline row offers; a custom place is not modelled.
    public enum Location: String, CaseIterable, Hashable, Sendable {
        case gettingInCar
        case gettingOutOfCar

        public var title: String {
            switch self {
            case .gettingInCar: "Getting in Car"
            case .gettingOutOfCar: "Getting out of Car"
            }
        }
    }

    /// How often the reminder recurs; stored and shown, not yet scheduled.
    public enum Repeat: String, CaseIterable, Hashable, Sendable {
        case never, daily, weekly, monthly, yearly

        public var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    }

    /// The days the inline Date chip offers.
    public enum DatePreset: CaseIterable, Hashable, Sendable {
        case today, tomorrow, thisWeekend, nextWeek

        public var title: String {
            switch self {
            case .today: "Today"
            case .tomorrow: "Tomorrow"
            case .thisWeekend: "This Weekend"
            case .nextWeek: "Next Week"
            }
        }

        /// The start of the preset's day: today, tomorrow, the coming Saturday, the coming Monday.
        public func date(at now: Date, calendar: Calendar = .current) -> Date {
            let today = calendar.startOfDay(for: now)
            switch self {
            case .today: return today
            case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: today) ?? today
            case .thisWeekend: return calendar.nextDate(after: today, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? today
            case .nextWeek: return calendar.nextDate(after: today, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) ?? today
            }
        }
    }

    /// The times of day the inline Time chip offers.
    public enum TimePreset: Int, CaseIterable, Hashable, Sendable {
        case morning = 9, midday = 12, afternoon = 15, evening = 18, night = 21

        public var title: String {
            switch self {
            case .morning: "Morning"
            case .midday: "Midday"
            case .afternoon: "Afternoon"
            case .evening: "Evening"
            case .night: "Night"
            }
        }

        public var hour: Int { rawValue }
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

    /// Tags in a stable, display order.
    public var sortedTags: [Tag.ID] { tags.sorted() }

    /// Incomplete and due on a day before today.
    public func pastDue(at now: Date, calendar: Calendar = .current) -> Bool {
        guard !completed, let due else { return false }
        return calendar.startOfDay(for: due) < calendar.startOfDay(for: now)
    }

    /// Turning the time on needs a date; turning the date off drops the time.
    public mutating func set(due date: Date?) {
        due = date
        if date == nil { hasTime = false }
    }

    /// Turning the time on proposes the next full hour, on the due day if there is one.
    public mutating func set(hasTime: Bool, at now: Date, calendar: Calendar = .current) {
        self.hasTime = hasTime
        guard hasTime else { return }
        let nextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? now
        let time = calendar.dateComponents([.hour, .minute], from: nextHour)
        let day = due ?? now
        due = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }

    /// A preset day keeps the time of day if one was set; none clears the date and the time.
    public mutating func set(datePreset preset: DatePreset?, at now: Date, calendar: Calendar = .current) {
        guard let preset else { return set(due: nil) }
        let day = preset.date(at: now, calendar: calendar)
        if hasTime, let due {
            let time = calendar.dateComponents([.hour, .minute], from: due)
            self.due = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day) ?? day
        } else {
            due = day
        }
    }

    /// A preset time turns the time on, on the due day or today; none turns the time off and keeps the day.
    public mutating func set(timePreset preset: TimePreset?, at now: Date, calendar: Calendar = .current) {
        guard let preset else {
            if let due { self.due = calendar.startOfDay(for: due) }
            hasTime = false
            return
        }
        let day = due ?? now
        due = calendar.date(bySettingHour: preset.hour, minute: 0, second: 0, of: day) ?? day
        hasTime = true
    }

    /// A title of only whitespace is no reminder.
    public var isBlank: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// The circle tap: incomplete starts completing; completing or completed reverts to incomplete.
    public mutating func toggle() {
        status = status == .incomplete ? .completing : .incomplete
    }
}

extension Reminder {
    /// One reminder edited in place: the draft the row's fields bind to, the value the database
    /// holds as far as this session has written it, so each write is only what changed since,
    /// and the value the row is sorted by until editing ends, so it keeps its place under any
    /// ordering. The session tells one editing of a row from a later one: a write started for
    /// a session that has ended reports to nobody.
    public struct Editing: Hashable, Sendable {
        public var draft: Reminder
        public var saved: Reminder
        public let place: Reminder
        public let session: UUID
        /// Why the draft's last write did not happen; the draft stays, and the next write tries again.
        public var failure: String?

        public var id: Reminder.ID { saved.id }

        /// Whether the database holds the draft as typed.
        public var isSaved: Bool { draft == saved }

        public init(draft: Reminder, saved: Reminder, place: Reminder, session: UUID) {
            self.draft = draft
            self.saved = saved
            self.place = place
            self.session = session
        }

        /// Editing a stored reminder: the draft starts as, and sorts as, the stored value.
        public init(_ reminder: Reminder, session: UUID) {
            self.init(draft: reminder, saved: reminder, place: reminder, session: session)
        }
    }
}
