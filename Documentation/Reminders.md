# Reminders

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Sources/Reminders/Reminder.Completion.swift

- `public enum Completion: Hashable, Sendable` — Whether the reminder is done. The grace period after the tap, during which it can be undone, is the application's (`Completion.Pending`), not the reminder's.

## Sources/Reminders/Reminder.Due.swift

- `public enum Due: Hashable, Sendable` — When a reminder is due: some time on a day, or at a moment on it. A time is never without a day, so a reminder cannot hold one.
- `public var hasTime: Bool` — Whether the time of day matters; without it the reminder is due some time that day.

## Sources/Reminders/Reminder.Filter.swift

- `public enum Filter: Hashable, Sendable` — A screen of reminders: one of the smart groups, one list, or a set of tags.
- `public static func contains(_ reminder: Reminder, in filter: Self, today: Range<Date>) -> Bool` — Whether a reminder belongs to the filter; `today` is the day the filter of that name shows. Flagged shows flagged reminders whatever their completion; the other smart groups show open ones, and a tag filter any reminder carrying one of its tags.
- `public static func removing(_ filter: Self, tag id: Tag<Reminder>.ID) -> Self?` — The filter without a tag that no longer exists: narrowed, or closed when it was the last one.
- `public static func removing(_ filter: Self, list id: List<Reminder>.ID) -> Self?` — The filter without a list that no longer exists: closed when it was that list.

## Sources/Reminders/Reminder.Location.swift

- `public enum Location: String, CaseIterable, Hashable, Sendable` — The two fixed locations the inline row offers; a custom place is not modelled.

## Sources/Reminders/Reminder.Ordering.swift

- `public enum Ordering: String, CaseIterable, Hashable, Sendable` — The raw value is the stored key; the cases are in the stock menu's order.
- `public static func areInIncreasingOrder(_ lhs: Reminder, _ rhs: Reminder, for ordering: Self) -> Bool` — The order a detail shows under the ordering, ties broken by position as the manual order has it: due dates ascending with none last, creation dates ascending, priorities descending then flagged first, titles as the locale compares them ignoring case.

## Sources/Reminders/Reminder.Repeat.swift

- `public enum Repeat: String, CaseIterable, Hashable, Sendable` — How often the reminder recurs; stored and shown, not yet scheduled.

## Sources/Reminders/Reminder.swift

- `public struct Reminder: Identifiable, Hashable, Sendable` — One reminder: what to do, in which list, by when, how urgent, and its tags. The rules are statics over a value; the instance members forward to them.
- `public var created: Date` — When the reminder came to be; the Creation Date ordering. A value made without a clock dates from before any record.
- `public static func isBlank(_ reminder: Self) -> Bool { reminder.title.trimmed.isEmpty }` — A title of only whitespace is no reminder.
- `public static func pastDue(_ reminder: Self, at now: Date, calendar: Calendar) -> Bool` — Incomplete and due on a day before today.
- `public static func toggling(_ reminder: Self) -> Self` — The circle tap flips the completion; the grace period around it is the application's.
- `public static func setting(_ reminder: Self, due date: Date?) -> Self` — A new day keeps the time of day if one was set; none drops the date and the time with it.
- `public static func setting(_ reminder: Self, hasTime: Bool, at now: Date, calendar: Calendar) -> Self` — Turning the time on proposes the next full hour, on the due day if there is one; turning it off keeps the day.

## reminders-apple/Hosts/Reminders/App.swift

- `@main struct Application: App` — The host: one scene around the application layer in `Reminders App`.
- `static let store = Reminder.Feature.live()` — The root store, held once for the process as the Point-Free Way has it.
