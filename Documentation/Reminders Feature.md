# Reminders Feature

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Sources/Reminders Feature/DependencyValues+Bootstrap.swift

- `public mutating func bootstrapDatabase() throws` — Opens the application's default database, creates the Reminders schema, and makes it the feature's database. In Debug every statement is traced, to the log while live and to the console in a preview, so the cost of a write can be measured rather than assumed.

## Sources/Reminders Feature/List.Draft.Feature.swift

- `public struct Draft: Hashable, Sendable` — The sheet's draft of one list: what is being typed, what the form opened with, whether the form creates the list or edits a stored one, and a session telling this presentation from any other.
- `@ComposableArchitecture2.Feature public struct Feature` — The form over a draft, presented by `Reminder.Feature` as a destination: Save and Cancel are decided by the parent, which reads the draft back.
- `public var failure: String?` — Why the last save did not happen; the draft stays, and Done tries again.
- `public var isSaving = false` — Whether a save is under way; Done is ignored until it has succeeded or failed.
- `public mutating func fail(_ reason: String)` — The save did not happen: the reason is shown and Done is enabled again.

## Sources/Reminders Feature/Reminder.Draft.Feature.swift

- `public struct Draft: Hashable, Sendable` — The sheet's draft of one reminder: what is being typed, what the form opened with (the sheet asks before discarding a draft that differs, and a save writes only what differs), whether the form creates the reminder or edits a stored one, and a session telling this presentation from any other: work started for a form that has closed reports to nobody.
- `@ComposableArchitecture2.Feature public struct Feature` — The form over a draft, presented by `Reminder.Feature` as a destination: Save, Cancel, and the tag intents are decided by the parent, which writes the database and hands the accepted tags back into the draft.
- `public var failure: String?` — Why the last save did not happen; the draft stays, and Done tries again.
- `public var isSaving = false` — Whether a save is under way; Done is ignored until it has succeeded or failed.
- `public mutating func fail(_ reason: String)` — The save did not happen: the reason is shown and Done is enabled again.

## Sources/Reminders Feature/Reminder.Feature.Destination.swift

- `@ComposableArchitecture2.Feature public enum Destination` — The one sheet the home can present: a reminder form or a list form.
- `extension Reminder.Feature.Destination.State: Sendable {}` — The macro-generated state carries only `Sendable` drafts; `Reminder.Feature.State` is `Sendable`.

## Sources/Reminders Feature/Reminder.Feature.swift

- `extension Reminder` — The Reminders feature. The database owns the records; the feature owns the open filter, the presented form, the row being edited in place with its draft, the search input, the day the screens call today, and the completion grace timer. What the screens show is read from the database through `@Fetch` properties, which follow every change to the tables they read; a user intent starts one targeted write, and the reads follow. A row edited in place is a draft in state until editing ends; typing writes nothing. Every write runs inside a task as the synchronous `database.write`, on the store's isolation, so writes land whole and in the order the user made them. A task that ends in a state change checks that the session it was started for is still the one on screen before it applies the change: a form is a session, and so is each editing of a row.
- `@ComposableArchitecture2.Feature public struct Feature` — `State.Feature` names the feature type explicitly; the macro would otherwise synthesize `typealias Feature = Feature`. `State`, `Action`, and `body` stay in the type body because the macro reads them.
- `public var destination: Destination.State?` — The form sheet being shown, if any.
- `public var editing: Reminder.Editing?` — The reminder whose row is open for editing in the detail, with its draft.
- `public var failure: String?` — Why the last write did not happen, until the next one.
- `public var today: Range<Date>?` — The day the screens call today, by the feature's calendar; nil until mounted.
- `public var lastSeed: Reminder.Sample.Seed?` — The last generated seed, for the debug menu to show and replay.
- `public var isSeeding = false` — Whether a seed is being written; the menu disables itself meanwhile.
- `public var detailWindow = Reminder.Window<Reminder.Filter>()` — How many rows of the open filter, and of the search, are read; each widens as the user nears its end and starts over for another filter or search.
- `@DebugSnapshotIgnored @Fetch public var detail: Reminder.Filter.Detail? = nil` — The open filter, read from the database; nil while no filter is open.
- `@DebugSnapshotIgnored @Fetch public var overview = Reminder.Overview()` — The home screen, read from the database.
- `@DebugSnapshotIgnored @Fetch public var results = Reminder.Search.Results()` — The search results, read from the database.
- `@DebugSnapshotIgnored @Fetch(Reminder.Completion.Pending.Request()) public var pending = Reminder.Completion.Pending()` — The reminders in their grace period, read from the database; the grace timer is driven by this value however a reminder came to be pending. The query is declared here rather than loaded at mount, so the reader the body observes is the shared one from the first evaluation on.
- `public subscript(draft id: Reminder.ID) -> Reminder` — A reminder as a draft for editing in place: the row's draft, or a placeholder once editing has ended. A write to any other reminder is dropped, so a field committing after editing ended cannot bring a deleted row back. A subscript, so a view binds to it through a key path (`$store[draft: id]`) rather than a closure-built binding.
- `private static let noList = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))` — The list a placeholder draft names when there is no list at all; never stored.
- `case appActivated` — The app came to the foreground: the day may have changed while it was away.
- `case detailEndReached` — The user scrolled close to the last row read: the next rows follow.
- `case seedGenerated(Reminder.Sample.Scale, seed: UInt64?)` — A generated sample at a scale; no seed value draws a fresh one.
- `case .backgroundTapped:` — A tap on the empty part of a list ends editing, or starts a new row in an idle list.
- `case .destination(.list(.saveButtonTapped)):` — A blank name is no list and no reminder: the sheet stays up. It also stays up until the write has succeeded; a failed one leaves the draft to try again, and a save under way is not started twice.
- `case let .destination(.reminder(.tagAdded(title))):` — The tags table owns the tags; the draft follows what it accepted, so adding a tag that exists in another case attaches the existing tag instead of a twin. A failure is the form's, and the draft is untouched; a success clears the last failure.
- `case .newReminderButtonTapped:` — Inside a list the new reminder is a row edited in place; from the home it is the sheet.
- `case let .reminderCompleteButtonTapped(id):` — The grace timer follows the stored status through `pending`: the period starts once the toggle is stored, and not at all when the write fails.
- `try store.modify` — The row being edited shows its draft, so the draft follows the stored completion.
- `case let .reminderDetailsButtonTapped(id):` — The sheet opens on the stored reminder, once the row's draft is written; a draft that cannot be written keeps its row open instead.
- `case let .reminderTapped(id):` — The row opens on the stored reminder, once the previous row's draft is written.
- `let sample = Reminder.Sample.generated(scale, seed: value, at: now, calendar: calendar)` — Generated and written off the main actor: a hundred thousand rows take seconds.
- `.onMount { state in` — The first run fills the database with the sample; any later run restores the open filter and the row being edited, before anything else runs. A grace period that was running when the app last quit resumes as soon as `pending` reads it. A read that fails is a failure, not a first run.
- `do` — Restored synchronously, so the detail's first read already sees the filter: a filter set from a task after the mount left the detail unread on relaunch.
- `.onChange(of: store.today, initial: true) { _, today, state in` — The day decides the overview counts and the Today filter: it is read again when the day changes, and the change is scheduled on the feature's clock for midnight.
- `.onChange(of: store.filter) { previous, filter, state in` — Leaving a filter ends the row being edited, as the stock app does. A row is only ever edited inside a filter, so a change from no filter is the mount restoring the filter and its row together, not the user leaving one.
- `.onChange(of: DetailQuery(filter: store.filter, place: store.editing?.place, today: store.today, limit: store.filter.flatMap { store.detailW` — The detail is read again for another filter or day, or when a row starts or stops being edited: the row being edited keeps the place it had, whatever the ordering says.
- `.onChange(of: ResultsQuery(search: store.search, limit: store.resultsWindow.limit(for: store.search)), initial: true) { previous, query, sta` — Typing waits for a pause before it is read: each read is two passes over every reminder, and the earlier task is cancelled by the next character, so a word costs one read rather than one per character. A token, the completed toggle, or a cleared field is read at once.
- `.onChange(of: store.pending, initial: true) { _, pending, _ in` — The grace period: `Pending.grace` after the set of pending reminders last changed, every reminder still pending is completed. The set is the observed query: the feature is remounted when it changes, by this feature's own write or another writer's, and every change restarts the period, so the latest tap, reversal, or external change gets the full period, and a set that empties cancels the timer. The mount counts as a change: a set already loaded when the feature mounts is a period that was running when the app last quit, and it resumes here.
- `public static let searchPause: Duration = .milliseconds(250)` — How long typing in the search field pauses before the reminders are read.
- `private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }` — The database access the tasks use. Synchronous, on the store's isolation: a write lands whole, in the order the actions came, before anything else runs. TCA26 cancels the earlier task of a repeated action, but a task that never suspends cannot observe that; it runs to its end, state change included, which is why each such change checks its session first.
- `private func attempt(_ body: () async throws -> Void) async throws` — Runs database work inside a task; a failure is kept for the user to see, and a cancellation ends the task quietly.
- `private func attempt(editing session: UUID?, _ body: () async throws -> Void) async throws` — As `attempt`, for a commit of the row being edited: the failure is the row's too, if that session is still open, so the draft stays with its reason.
- `private func attempt(form session: UUID, _ body: () async throws -> Void) async throws` — As `attempt`, for work done for a form: the failure is the form's, if that form is still up; a form that closed meanwhile is told nothing.
- `private func perform(_ body: @escaping (Database) throws -> Void)` — Runs one write as a task of the feature.
- `private func startNewReminder(in list: List<Reminder>.ID, _ state: inout State)` — Opens an empty reminder at the end of a list for editing, once the row being edited is written. The row takes its place in the manual order from the database, so the session starts once the row is stored.
- `private func endEditing(_ state: inout State)` — Ends the row being edited: a blank one is removed, any other one is written as typed. A draft that cannot be written stays open with its reason, so Done can try again.
- `private func continueEditing(_ state: inout State)` — Return in the title: a blank row ends editing; a titled row is written and an empty row opens directly beneath it, in the same list, sorted as its neighbour until editing ends so it stays beneath under any ordering.
- `private func commit(_ editing: Reminder.Editing?, in db: Database) throws` — Writes an editing session back: a blank draft deletes the row, any other writes what differs from what the database holds. A row deleted meanwhile stays deleted. Throws when the write fails, so the session it belongs to stays open.
- `@discardableResult` — Writes what a draft changed against the value the database holds: the changed columns, the tags removed, and the tags added. Nothing is inserted, so a row deleted meanwhile stays deleted; returns whether the row still exists.
- `private func save(_ form: Reminder.Draft.Feature.State)` — Saves the reminder form and closes it; the result is the form's only while that form is still the one presented.
- `fileprivate mutating func endEditing(_ session: UUID?)` — Closes the editing session, if it is still the one open; a later session is left alone.
- `private struct DetailQuery: Equatable` — What the detail read depends on.
- `private struct ResultsQuery: Equatable` — What the search read depends on.
