# Reminders Application

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Sources/Reminders Application/Reminder.Completion.Pending.swift

- `public struct Pending: Hashable, Sendable` — The grace period: the reminders whose completion was tapped and can still be undone. The period is counted from the set's last change, so the latest tap or reversal gets the whole of it; when it elapses every member is completed.
- `public static let grace: Duration = .seconds(5)` — How long a tap can be undone.
- `public static func toggling(_ pending: Self, _ id: Reminder.ID) -> Self` — The tap: an incomplete reminder starts its period; one in its period is reverted.
- `public static func elapsing(_ pending: Self) -> Self { Self() }` — The period elapsed: nothing is pending any more.

## Sources/Reminders Application/Reminder.Due.Preset.Time.swift

- `public enum Time: Int, CaseIterable, Hashable, Sendable` — The times of day the inline Time chip offers; the raw value is the hour.
- `public static func setting(_ reminder: Self, timePreset preset: Due.Preset.Time?, at now: Date, calendar: Calendar) -> Self` — A preset time turns the time on, on the due day or today; none turns the time off and keeps the day.

## Sources/Reminders Application/Reminder.Due.Preset.swift

- `public enum Preset: CaseIterable, Hashable, Sendable` — The days the inline Date chip offers.
- `public static func date(for preset: Self, at now: Date, calendar: Calendar) -> Date` — The start of the preset's day: today, tomorrow, the coming Saturday, the coming Monday; today when the calendar cannot say.
- `public static func setting(_ reminder: Self, datePreset preset: Due.Preset?, at now: Date, calendar: Calendar) -> Self` — A preset day keeps the time of day if one was set; none clears the date and the time.

## Sources/Reminders Application/Reminder.Editing.swift

- `public struct Editing: Hashable, Sendable` — One reminder edited in place: the draft the row's fields bind to, the value the database holds as far as this session has written it, so the commit is only what changed since, and the value the row is sorted by until editing ends, so it keeps its place under any ordering. The session tells one editing of a row from a later one: a write started for a session that has ended reports to nobody.
- `public var failure: String?` — Why the draft could not be written when editing ended; the draft stays, and Done tries again.
- `public var isSaved: Bool { draft == saved }` — Whether the database holds the draft as typed.
- `public init(_ reminder: Reminder, session: UUID)` — Editing a stored reminder: the draft starts as, and sorts as, the stored value.

## Sources/Reminders Application/Reminder.Filter.Counts.swift

- `public struct Counts: Hashable, Sendable` — The counts on the overview grid: open reminders only.

## Sources/Reminders Application/Reminder.Filter.Detail.swift

- `public struct Detail: Hashable, Sendable` — One filter as read from the database: its list's color when it is a list, its preference, the first rows it shows in the preference's order, each with the color of the list it belongs to, how many rows it has in all, and how many of those are completed.
- `public private(set) var ids: [Reminder.ID]` — The rows' identifiers, kept so a screen compares them without walking the rows.
- `public var hasMore: Bool { rows.count < total }` — Whether the query has rows beyond the ones read.
- `public struct Row: Identifiable, Hashable, Sendable` — One reminder in a detail, tinted by its list.

## Sources/Reminders Application/Reminder.Filter.Preference.swift

- `public struct Preference: Hashable, Sendable` — How a filter sorts and whether it shows completed reminders; persisted per filter.
- `public static func `default`(for filter: Reminder.Filter) -> Self` — Completed shows completed reminders; every other filter hides them until asked.

## Sources/Reminders Application/Reminder.Overview.swift

- `public struct Overview: Hashable, Sendable` — The home screen as read from the database: the user's lists in their order with their open counts, the smart-group counts, the tags at least one reminder carries, and every tag ranked by use for the picker.

## Sources/Reminders Application/Reminder.Sample.Scale.swift

- `public struct Scale: Hashable, Sendable` — How much data a generated sample holds: the sizes the debug seed menu offers.
- `public static let medium = Scale(lists: 10, remindersPerList: 100, tags: 30)` — About a thousand reminders.
- `public static let large = Scale(lists: 30, remindersPerList: 500, tags: 100)` — Fifteen thousand: past what a person keeps, enough to see every list scroll.
- `public static let extreme = Scale(lists: 100, remindersPerList: 1_000, tags: 200)` — A hundred thousand: where the queries and the observation fan-out give way first.
- `public struct Seed: Hashable, Sendable` — What the last generated seed was: the scale and the seed value, so it can be replayed.
- `public var description: String { "0x" + String(value, radix: 16, uppercase: true) }` — The seed as the menu shows it.
- `public static func generated(_ scale: Scale, seed: UInt64, at now: Date, calendar: Calendar) -> Reminder.Sample` — A deterministic generator: the same seed gives the same sample, so a regression measured at a scale can be reproduced and screenshots compared. Dates spread over the year around `now`; about a fifth of the reminders are completed, a tenth flagged, a third dated.
- `enum Words` — The word lists the generator draws from; small on purpose, so titles repeat and the title ordering has ties to break.
- `public struct Random: RandomNumberGenerator, Hashable, Sendable` — A small seedable generator (SplitMix64), so a sample is a pure function of its seed.
- `mutating func chance(_ numerator: Int, in denominator: Int) -> Bool { next(in: 0..<denominator) < numerator }` — True `numerator` times in `denominator`.

## Sources/Reminders Application/Reminder.Sample.swift

- `public struct Sample: Hashable, Sendable` — A set of records to fill the database with: what the first run starts from, and what the seed button resets to.
- `public static func sample(at now: Date) -> Sample` — The reference fixture relative to a given now, so tests can fix the calendar: three lists, eleven reminders around today, seven tags.
- `return UUID(uuidString: "00000000-0000-0000-000A-" + String(repeating: "0", count: 12 - hex.count) + hex)!` — A fixture identifier sits in a segment the incrementing test generator never fills.

## Sources/Reminders Application/Reminder.Search.Results.swift

- `public struct Results: Hashable, Sendable` — The search as read from the database: the first matches grouped under their lists, open ones first and by due date, how many matches there are in all, the number of completed matches whether or not they are shown, and the tags completing a typed prefix.
- `public var shown: Int { sections.reduce(0) { $0 + $1.reminders.count } }` — How many matches are shown.
- `public var hasMore: Bool { shown < total }` — Whether the search has matches beyond the ones read.
- `public struct Section: Identifiable, Hashable, Sendable` — The matches in one list.

## Sources/Reminders Application/Reminder.Search.swift

- `public struct Search: Hashable, Sendable` — What the user typed into search: free text plus committed tokens.
- `public enum Token: Hashable, Identifiable, Sendable` — A committed search term: free text the reminder must contain, or a tag it must carry.
- `public var tagPrefix: String?` — Typed `#` starts tag completion.
- `public var matchesReminders: Bool { isActive && (tagPrefix == nil || !tokens.isEmpty) }` — Whether the search names reminders at all: a tag prefix alone offers suggestions, not the whole database.
- `public var matchedText: String { tagPrefix == nil ? text : "" }` — The free text the reminders must contain; none while a tag prefix is being typed.
- `public var tags: [Tag<Reminder>.ID] { tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } } }` — The tags already committed as tokens.
- `public static func committingText(_ search: Self) -> Self` — Submitting the field commits the trimmed text as a near token; a tag prefix is left for the suggestions.

## Sources/Reminders Application/Reminder.Session.swift

- `public struct Session: Hashable, Sendable` — Where the user is: the open filter and the row being edited in place, kept across launches.

## Sources/Reminders Application/Reminder.Window.swift

- `public struct Window<Key: Hashable & Sendable>: Hashable, Sendable` — How many rows of a screen's query are read: a screen reads its first rows and widens as the user nears the end, so the store never holds more than the user has scrolled to. A window belongs to a key (the filter, the search); another key starts at the first step.
- `public var rows: Int?` — Rows read for `key`; nil reads them all.
- `public static var margin: Int { 60 }` — A row this many from the end asks for the next step.
- `public func limit(for key: Key) -> Int?` — The limit for a key: its own when the window is for it, the first step otherwise.
- `public mutating func widen(for key: Key, shown: Int, total: Int)` — One step wider, while there is more to show.
- `public mutating func extend(for key: Key, by count: Int)` — Wider by a few rows, for rows added inside the window.
- `public mutating func open(for key: Key)` — Everything, for when the user is taken to the end.
- `public static func nearsEnd(_ index: Int, of shown: Int, total: Int) -> Bool` — Whether a row at an index is close enough to the end to ask for more.
