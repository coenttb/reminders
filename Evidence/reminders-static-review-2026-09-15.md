# Reminders static review, 2026-09-15

> Acted on the same day in four waves (correctness, decoupling, tests and documentation, fleet convergence) plus a residue batch; the dated entries in `RESEARCH.md` record what was done and what the measurements showed. Two claims below were corrected in the doing: `load` kept orphan preference keys rather than dropping them, and the fixtures' identifiers collided with the incrementing test generator.

Read-only review of the Reminders example at `main` (5a876f7 and the three commits below it). Nothing was built, run, edited, or committed. Every file under `reminders/` and `reminders/reminders-apple/` was read, including the five test files; the four sibling examples were read for the shared conventions only.

Claims below were checked against the library sources rather than taken from the skills or from memory:

- TCA26 (`/Users/coen/Developer/pointfreeco/TCA26`): `onChange` compares against the value it last recorded and fires at most once per hooks pass (`FeatureModifiers/OnChange.swift:55-77`); a modifier's base mounts before the modifier itself, so `onMount` runs before any `onChange` records its first old value (`FeatureModifier.swift:123-127`); tasks added inside an `onChange` run cancel that run's earlier tasks (`Internal/Core.swift:347-390`); store tasks start immediately up to their first suspension (`FeatureDynamicProperties/FeatureStore.swift:487`); a task's non-cancellation error is reported through `reportIssue` (`FeatureStore.swift:498-503`); `TestStoreActor.expect` is synchronous (`Testing/TestStoreActor.swift:948`). There is no debounce anywhere in `onChange`; the earlier review's claim was wrong and stays wrong.
- GRDB (DerivedData checkout): `foreignKeysEnabled` defaults to `true` (`GRDB/Core/Configuration.swift:28`); async `write` throws `CancellationError` when its task is cancelled (`GRDB/Core/DatabaseWriter.swift:131`).
- StructuredQueries: `insert … onConflictDoUpdate: { _ in }` renders `ON CONFLICT DO NOTHING` (`Statements/Insert.swift:842`); `upsert` updates every non-key writable column and therefore also renders `DO NOTHING` on a table whose only column is the key (`Insert.swift:708-720`).
- sqlite-data `Examples/Reminders`: the `tags` table is `COLLATE NOCASE` there too (`Schema.swift:208`); typing `#` loads tag suggestions and leaves the previous results untouched (`SearchReminders.swift:95-104`).

Deliberate differences recorded in `RESEARCH.md` (no FTS, no sync, `@Dependency` instead of `@FeatureEnvironment`, no `@FetchAll` in views, sheets as `Destination` child features, synchronous mount load, sample as the seed) are not reported.

## Ranked findings

### 1. A tag renamed only in case is silently lost on relaunch (correctness)

`Lists.rename(tag:to:)` replaces `Tag("car")` with `Tag("Car")` in the value (`reminders/Sources/Reminders/Lists.swift:170-176`). `Lists.persist` then inserts the new title with `onConflictDoUpdate: { _ in }` (`reminders/Sources/Reminders SQLiteData/Lists+SQLiteData.swift:96`), which is `DO NOTHING`, and the `tags` primary key is `COLLATE NOCASE` (`Lists+SQLiteData.swift:38`), so the insert conflicts with the old row and the delete on line 98 keeps it (`IN` compares under the column's collation). `Lists.load` returns `car`; the taggings written on lines 103-108 carry `Car` and match the parent under NOCASE, so nothing fails, the rename just does not survive. The same path affects `add(tag:)` when a tag differing only in case already exists in the database but not in the value.

Underneath is an identity mismatch: the database treats tag titles as case-insensitive, the domain's `Set<Tag>` and `Tag.ID` are case-sensitive, and only `add(tag:)` (`Lists.swift:165-168`) and `tag(titled:)` honour the case-insensitive rule; `upsert(_ reminder:)` (`Lists.swift:126`) and `rename` do not, so a reminder carrying `Car` creates a twin of `car` in the value, and `.tags(["car"])` does not match a reminder tagged `Car`.

Change: make the conflict clause update the title, `onConflictDoUpdate: { $0.title = $1.title }` (the two-argument overload, `Insert.swift:59`), so a case change is written; and give the domain one canonicalising point, a `Lists.canonical(_ id: Tag.ID) -> Tag.ID` used by `upsert(_ reminder:)`, `rename`, `matches`, and `reminders(in: .tags)`, or store tags lowercased and keep the display title on `Tag`. Add a stored-form test that renames `social` to `Social` and reloads.

### 2. The draft subscript resurrects a deleted row (correctness risk)

`Lists[draft:]` fabricates a reminder when the id is gone and its setter upserts unconditionally (`Lists.swift:99-105`). `endEditing` deletes a blank row (`Lists.swift:55-59`) while `Reminder.Editor` still holds `draft(reminder.id)` from `Root.Detail` (`reminders/reminders-apple/Sources/Reminders App/Root.Detail.swift:31`). Any write the editor's `TextField`s make after Done, a background tap, or a scene-phase change (resignation of focus commits through the binding, and `onChange(of: focus)` on `Reminder.Editor.swift:97-99` can write "New Reminder" into a row that was just removed) re-inserts the reminder at a new position, with `editing` already nil, so it appears as an ordinary blank or "New Reminder" row. The Messages overview hit the same class of late write on edit exit.

Change: make the setter a no-op for an id the value no longer holds (`set { guard reminder(newValue.id) != nil else { return }; upsert(newValue) }`) and have the getter return the last known reminder rather than a fresh one with an uncontrolled `UUID()` list id (`Lists.swift:103`), which the domain should never mint. Cover it with a domain test: `endEditing()` then `lists[draft: id] = reminder` leaves `reminders` unchanged.

### 3. Free-text search tokens cannot be committed on a device (functional gap)

`Lists.Search.commitText()` requires a trailing tab (`reminders/Sources/Reminders/Lists.Search.swift:35-40`), driven by `onChange(of: store.search.text)` (`reminders/Sources/Reminders Feature/Lists.Feature.swift:193-195`). Nothing in `Root` submits the search field (`Root.swift:55-63` has no `onSubmit(of: .search)`), and the software keyboard has no tab, so `.near` tokens only exist with a hardware keyboard. The token rendering on `Root.swift:57` and the `.near` branch of `matches` are unreachable otherwise.

Change: add `.onSubmit(of: .search) { store.send(.searchSubmitted) }` in `Root`, make `commitText()` commit the trimmed text unconditionally, drop the `onChange(of: store.search.text)` modifier, and remove the tab rule from the doc comment on line 35.

### 4. "Clear completed" deletes reminders still in their grace period (correctness)

`deleteCompleted(matching:olderThanMonths:at:)` keeps `reminder.completed` (`Lists.Search.swift:79-80`), which is true for `.completing` (`Reminder.swift:136`), and the Clear menu is enabled by the same count (`Lists.Search.View.swift:51,78`). A reminder tapped five seconds ago, still shown so the tap can be undone, is deleted by "All Completed".

Change: filter on `status == .completed` in `deleteCompleted`, and count `completed` the same way in the search header so the "N Completed" and the menu agree with what would be deleted.

### 5. The ordering's stored key is its display label (persistence coupling)

`Lists.Ordering` raw values are the menu strings ("Due Date", "Manual", …) (`reminders/Sources/Reminders/Lists.Detail.swift:78-83`), and `Lists.Detail.Preference.Record` stores `rawValue` (`reminders/Sources/Reminders SQLiteData/Lists.Record.swift:34`). Renaming or localising a label changes stored data; the fallback on `Lists.Record.swift:42` would silently reset every preference to due date. `Reminder.Repeat` does this right with identifier raw values and a computed `title` (`Reminder.swift:69-75`).

Change: raw values `dueDate`, `manual`, `priority`, `title`; a `title` property in the domain (as `Repeat.title`) or in `Reminders View` next to `systemImage` (`Lists.Detail.View.swift:187-195`), which then reads `ordering.title` instead of `rawValue` on lines 165 and 171. Pre-launch, so no migration.

### 6. The flag intent is dead from the row down to the domain (dead code)

`Reminder.Row` stores `flag` and never uses it (`Reminder.Row.swift:16,26,35`; the swipe actions on lines 83-86 are Delete and Details). The parameter is threaded through `Lists.Detail.View` (lines 20, 41, 58, 100), `Lists.Search.View` (17, 29, 40, 99), `Root.swift:36`, and `Root.Detail.swift:37` to `.reminderFlagButtonTapped`, which is the only caller of `Lists.flag(_:)` (`Lists.Feature.swift:136-137`, `Lists.swift:188-191`). The forms toggle `flagged` through the binding instead (`Reminder.Form.swift:212`). The sibling examples carry no dead callbacks.

Change: remove `flag:` from the three views and both call sites, and either remove `reminderFlagButtonTapped` and `Lists.flag` or keep them only if the context menu gains Flag (the stock app has one on long press).

### 7. The "Done needs a title" rule lives twice in the views and nowhere in the domain or feature (decoupling, drift)

`Reminder.Form.swift:129` and `Reminder.List.Form.swift:92` disable Done on `trimmingCharacters(in: .whitespaces)`, while the domain's `Reminder.isBlank` trims `.whitespacesAndNewlines` (`Reminder.swift:197`); a title of one newline is savable from the sheet and deleted by `endEditing`. The feature saves whatever the child holds (`Lists.Feature.swift:85-90`), so the rule exists only as a disabled button.

Change: `Reminder.List.isBlank` in the domain, both forms disable on `reminder.isBlank` / `list.isBlank`, and the two save cases guard on it (`guard !form.reminder.isBlank else { return }`), which the feature tests can then assert.

### 8. `Reminder.Editor` calls mutating domain methods from the view, on the app's clock (rules and testability)

The chips call `reminder.set(datePreset:at:)`, `set(timePreset:at:)` and assign `repeats` and `location` through the binding (`Reminder.Editor.swift:104,107,128,131,155,162-175`). `README.md:58` says a view "never calls a mutating domain method"; `Reminder.Form` keeps the letter of that rule through key-path subscripts (`Reminder.Form.swift:228-244`) but the effect is the same. The `now` these rules run against is `Root`'s `@Dependency(\.date.now)` read in the view (`Root.Detail.swift:17`), not the feature's, and none of the chip paths can be exercised by a feature test.

Change: the chips are intents, not typing, so give the editor `setDate: (Reminder.DatePreset?) -> Void` and `setTime: (Reminder.TimePreset?) -> Void` callbacks, add `datePresetSelected`/`timePresetSelected(Reminder.ID, …)` actions that run the domain rules with the feature's `now`, and keep the binding for the two text fields, `repeats`, and `location`. If the binding route is preferred instead, amend the README sentence to say a view mutates a draft only through its binding, so the rule and the code agree.

### 9. `Root` decides whether a sheet is "new" by looking the draft up in the lists (decoupling)

`Root.swift:90` and `115` compute `isNew` from `store.lists`, so the app layer re-derives what the parent feature knew at presentation (`newReminderButtonTapped`/`addListButtonTapped` versus the two details actions, `Lists.Feature.swift:70-71,114-115,121-126,133-135`). It also changes meaning mid-sheet: a new reminder's draft is not in the lists until Save, which is right today, but a future "save as you type" would flip the title from New Reminder to Details.

Change: `isNew: Bool` on `Reminder.Feature.State` and `Reminder.List.Feature.State`, set by the parent when it builds the destination; `Root` reads `form.isNew`.

### 10. Leaving the app ends editing on `.inactive`, not `.background` (behaviour)

`Root.Detail.swift:46-48` sends Done for any phase other than `.active`, which includes Control Center, the app switcher peek, an incoming call banner, and system alerts. The survey wording is "leaving the app".

Change: `if phase == .background`.

### 11. `Lists.Detail.View` and `Reminder.Editor` parameter lists (decoupling)

`Lists.Detail.View.init` takes sixteen parameters (`Lists.Detail.View.swift:31-48`), of which `complete`, `flag`, `delete`, `details` are the same four that `Lists.Search.View` takes (`Lists.Search.View.swift:25-31`) and forwards to `Reminder.Row`; `edit`, `submit`, `done`, `backgroundTapped`, `draft` are the inline-editing set; `move`, `order`, `toggleCompleted`, `newReminder` are the detail's own. The View tests construct them twice with fourteen dummy closures each (`Lists.View Tests.swift:14-15`).

Change: a `Reminder.Row.Actions` value (`complete`, `delete`, `details`; `edit` optional) passed to `Reminder.Row`, `Lists.Detail.View`, and `Lists.Search.View`, and a `Reminder.Editor.Actions` value (`submit`, `details`, plus the preset callbacks from finding 8) passed to the editor and the detail. That keeps one callback per intent while collapsing the three call sites to one struct literal each; the `flag` removal in finding 6 takes one more off.

### 12. The draft binding derivation in `Root.Detail` (decoupling, cost)

`$store.lists.draft($0)` (`Root.Detail.swift:31,53-57`) projects `Binding<Lists>` through `Lists[draft:]`; each keystroke reads the whole `Lists`, upserts, and writes the whole value back through the store's `modify` subscript, which runs the hooks: `onChange(of: store.lists)` persists the entire graph (lists, tags, every reminder, all taggings deleted and re-inserted, `Lists+SQLiteData.swift:90-114`), and `.animation(.default, value: store.lists)` on `Root.swift:54` and `Lists.Detail.View.swift:120` starts an animation transaction on every character. It is correct (TCA26 starts each persist immediately and cancels the previous one, GRDB rolls a cancelled write back, so the last value always wins), just heavier than it needs to be, and `editingPlace`, which is not stored, is part of `Lists`'s equality and triggers a persist of its own (`Lists.swift:18`, `Lists.Detail.swift:113-117`).

Change: keep the key-path binding (it is the right shape) but pass `onChange`'s `oldValue` into `Lists.persist(current, previous:in:)` so only rows that differ are written and taggings are rewritten only for reminders whose tags changed; give `Reminder.Tagging` a composite key `(reminderID, tagID)` instead of `AUTOINCREMENT`, which today grows the sequence by the whole tagging count on every keystroke (`Lists+SQLiteData.swift:43,103-108`); and move `editingPlace` out of the equality that drives persistence, either into `Lists.Feature.State` or behind a custom `==`.

### 13. Typing `#` alone lists every reminder (behaviour)

`matches` blanks the text when it has a tag prefix and then applies no filter when there are no tokens (`Lists.Search.swift:52-61`), so the results section under the suggestions shows the whole database while the user types a tag name. The reference keeps the previous results untouched in that state.

Change: `guard search.tagPrefix == nil || !search.tokens.isEmpty else { return [] }` in `matches`, or have `Lists.Search.View` hide the results while `tagPrefix != nil`.

### 14. Uncontrolled dates and the machine calendar (Dependencies usage)

`Reminder.Form.init` defaults `now: Date = Date()` (`Reminder.Form.swift:35`), and `Lists.Feature.State.init(lists: Lists = .sample)` (`Lists.Feature.swift:27`) reaches `Lists.sample`, which calls `Date()` (`Lists+Sample.swift:6`), on every store construction including the test stores. Every calendar rule uses `Calendar.current` (`Reminder.swift:90,146,152,165,177,187,189; Lists.Search.swift:78; Reminder.Due+Text.swift:17`), so the weekday assertions in the domain tests (`Lists Tests.swift:141-142`) and the wording in the View tests depend on the machine's locale and first weekday; Messages threads a `calendar` parameter (`Conversation+DateDescription.swift:9`).

Change: remove the `Date()` default; default the feature state to an empty value (`Lists(lists: [])`, as Messages defaults to `Conversations()`); take `calendar: Calendar = .current` on the domain rules and the description helpers, and pass a fixed Gregorian calendar in tests.

## Point-Free Way deviations not already covered

- **Test targets link transitive products.** `Reminders Tests` links `Tagged`; `Reminders SQLiteData Tests` links `SQLiteData` and `Tagged`; `Reminders Feature Tests` links `ComposableArchitecture2`, `Dependencies`, `SQLiteData`, `Tagged` (`reminders/Package.swift:51-80`); `Reminders App Tests` links `ComposableArchitecture2` and `Dependencies` (`reminders-apple/Package.swift:53-64`). `pfw-testing` says a test target must not link what it gets transitively and that `Dependencies` in particular must never be linked to a test target (only `DependenciesTestSupport`). The sibling core packages link only the tested targets plus `SQLiteData` in the storage tests, so Reminders is the fleet's outlier. Change: reduce each test target to the tested targets, `DependenciesTestSupport`, and `ComposableArchitectureTestSupport`.
- **Non-exhaustive feature tests by default.** Both feature tests run under `TestExhaustivity.$current.withValue(.off)` (`Lists.Feature Tests.swift:21,59`), and `store.expect { _ in }` on line 25 consumes the timer's modification without asserting it. `pfw-tca26` prefers exhaustive tests with the change asserted in `send`'s trailing closure and `.dependency(\.exhaustivity, .off)` as a trait when needed. The whole fleet uses the task-local, so this is a fleet decision; if it stays, at least assert the timer's change: `store.expect { $0.lists.reminders[0].status = .completed }`.
- **Seeds shared with app code.** `pfw-sqlite-data/references/testing.md` says tests must own their seeds; here `Lists.sample` is the app seed and every test's fixture, and the tests hard-code its counts (`Lists Tests.swift:11-13,53,64,87-89`; `Lists.Feature Tests.swift:40`). The README makes the shared sample a rule, so this is an accepted trade-off; the cost is that any change to the fixture rewrites eight assertions.
- **Action ordering.** `pfw-tca26` asks for alphabetised cases; `doneButtonTapped` precedes `destination` (`Lists.Feature.swift:36-37`) and the `switch` handles `doneButtonTapped` before `deleteCompletedButtonTapped` (`Lists.Feature.swift:79-82`).
- **Schema defaults.** `pfw-sqlite-data/references/migrations.md` gives id columns `NOT NULL ON CONFLICT REPLACE DEFAULT (uuid())` and non-null columns `ON CONFLICT REPLACE` defaults; the migration has plain `NOT NULL DEFAULT` (`Lists+SQLiteData.swift:12-61`). Harmless while every id comes from `@Dependency(\.uuid)`, but a `Draft` insert without an id would fail rather than mint one. Low; note only.
- **Child features with an empty `Update` and parent-handled actions.** `Reminder.Feature` and `Reminder.List.Feature` declare actions they never handle (`Reminder.Feature.swift:25-37`, `Reminder.List.Feature.swift:22-31`); the parent pattern-matches them. `pfw-tca26` offers events (`store.post`) for child-to-parent communication. The Destination shape is ruled, so this is only a note: the two form features are draft holders, and the `Prompt`-style dismissal-on-any-action does not apply because Save must not dismiss on failure (finding 7).
- **Multi-line action closures in views.** `pfw-modern-swiftui` moves multi-line logic into named private methods; `Lists.Detail.View.swift:121-130` (focus and the 80 ms scroll) and `Reminder.Form.swift:136-143` inline it.

## Test coverage gaps and smells

Feature (`Lists.Feature Tests.swift`):

- The grace timer is tested with `ImmediateClock`, so the restart on a second tap and the revival at mount (`initial: true`) are untested; use `TestClock`, tap twice, advance four seconds, assert still completing, advance one more.
- The load path is never exercised through the feature (only `Lists.load` directly in the storage test); a second `TestStoreActor` after `dismount` on the same database would prove the mount restores `detail` and `editing`.
- Untested actions: `backgroundTapped` (both branches), `reminderTapped`, `reminderDetailsButtonTapped` ending editing, `listDeleted` with the default-list re-creation on `Lists.Feature.swift:113`, `listDetailsButtonTapped` and the list form's save and cancel, `tagDeleted`, `tagRenamed` through the destination, `deleteCompletedButtonTapped`, `searchTagTapped` and the `showCompleted` reset on `isActive`, `searchCompletedButtonTapped`, `seedButtonTapped`, and the `onChange(of: detail)` ending editing.
- Both tests are long scenarios ("… and everything persists"); the second `expect`-free assertions rely on non-exhaustivity. One behaviour per test would make a failure name the rule that broke.

Domain (`Lists Tests.swift`): no test for `Lists.Search.commitText`, `rankedTags`, `Lists[draft:]` (including the deleted-id case in finding 2), `upsert(_ list:)` position assignment, `delete(tag:)` narrowing or closing a `.tags` detail, `matches` with a `#` prefix, `Reminder.matches` on notes and tags, `pastDue`, `Array.move(offsets:to:)` against SwiftUI's semantics (moving up versus down), or tag identity across case (finding 1).

Stored form (`Lists+SQLiteData Tests.swift`): the round trip renames `social` to `friends` (a different word) so it never meets finding 1; add a case-only rename, a preference row for an unknown detail id (dropped silently by `load`, `Lists+SQLiteData.swift:78`), and a second `persist` that removes a list to prove the cascade and the tagging rebuild.

View and App: the View test is a constructor smoke test (`Lists.View Tests.swift:9-24`) and uses the wall-clock `Lists.sample` on line 47; `discardTitle` and `palette` are public and untested; `Root Tests` sends one action through a live `Store` rather than testing anything `Root` composes. If these targets are to earn their keep, snapshot or `ViewInspector`-free assertions on `dueDescription` edge days (across DST, `2...6` boundary at day 7) with an explicit calendar are the cheapest wins.

## Naming and documentation

- `Reminder.Due+Text.swift` names no type (`Reminder.Due` does not exist); the repository rule (`README.md:18`) and the Messages precedent (`Conversation+DateDescription.swift`) give `Reminder+DueDescription.swift`. The file also imports SwiftUI it does not use (`Reminder.Due+Text.swift:3`); `Reminder.Row.swift:4` imports `Tagged` and `Root.Detail.swift:2` imports `Foundation` without using them.
- `README.md:129` still shows `Lists.Detail.View(detail, lists: store.lists, now: now, …)` built inside `navigationDestination(item:)`, the exact shape `RESEARCH.md:195` records as the stale-screen bug that `Root.Detail` replaced. Update the snippet to `Detail(detail, store: store)`.
- The migration name is a sentence listing columns (`Lists+SQLiteData.swift:11`); the fleet's other migrations name tables. Since the schema is rewritten pre-launch it will keep changing; "Create the Reminders tables" is enough until a second migration exists.
- `Lists.Search.commitText`'s comment documents the tab rule (finding 3); `Lists[draft:]`'s comment documents the resurrection (finding 2); both should change with the code.
- `Tag.Picker.swift:64` titles the add alert `editing == nil ? "New tag" : "Edit tag"`, but that alert is only ever the add alert; the edit alert is the next modifier. The condition is dead.
- `Lists.Feature.swift:120` comments "Inside a list the new reminder is a row edited in place; from the home it is the sheet", which is accurate; `Lists.Detail.View.swift:6-9`, `Reminder.Editor.swift:12-15`, and the stored-form comments read as the repository asks, plain prose describing the rule. `Reminder.Row.swift:7-10` still says Details and Delete are the swipe actions and is right; the type-level comment in `Lists.swift:4-7` is the clearest statement of the domain-first rule in the tree.

## Sibling consistency (Maps, Messages, Music, Safari)

- Feature shape (`Update`, synchronous `onMount` load, seed as a task, `onChange` persist, `withErrorReporting` on the read) is identical across the five features; Reminders matches.
- Hosts (`@State private var store = X.Feature.live()`) and `live()` (`prepareDependencies { try! … }`) are identical in all five; `pfw-tca26` suggests a `static let` store, which would be a fleet change, not a Reminders one.
- Messages defaults its state to an empty value and seeds with `sample(at: now)` in the mount; Maps, Music, Safari, and Reminders default the state to the static sample (Reminders' static sample reads the wall clock, finding 14).
- Messages passes `calendar` into its date wording; Reminders does not (finding 14).
- Reminders' test targets link the most transitive products in the fleet (PFW section above); the siblings link only the tested targets plus `SQLiteData`.
- Reminders is the only example whose views receive a callback that no view uses (finding 6).
- `insert … onConflictDoUpdate: { _ in }` as a `DO NOTHING` seed appears in Maps too (`Places+SQLiteData.swift:48`); there it is correct because the key is a plain name, so the NOCASE problem is Reminders-only.

## Checked and found sound

- No persist race: each `onChange(of: store.lists)` run cancels the previous persist, the new task reaches `database.write` before control returns, and GRDB rolls back a cancelled write, so the newest whole value is always the last one written.
- `onChange(of: store.lists.detail)` does not fire at launch: the mount's mutation happens before the modifier records its first old value, so a restored `editing` row survives relaunch as `RESEARCH.md:212` says.
- The completion timer restarts on every tap and revives at mount exactly as documented.
- Sorting is deterministic: Swift's `sorted` is stable, `precedes` breaks every tie on `position`, positions are unique by construction (`upsert` uses max+1, `continueEditing` shifts the tail), and `editingPlace` substitution yields a consistent order for the edited row.
- `Lists.persist` order (lists, tags, reminders, taggings, preferences, state) respects the foreign keys with cascades on, and runs in one GRDB transaction.
- The `Destination` sheets bind through scoped stores, so nothing force-unwraps on dismissal.
