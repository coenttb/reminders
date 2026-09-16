# Reminders Feature Tests

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Tests/Reminders Feature Tests/Reminder.Feature Tests.swift

- `try $0.defaultDatabase.write { db in try Reminder.sample(at: Date(timeIntervalSince1970: 1_234_567_890)).replace(in: db) }` — The database starts initialised with the sample, so the mount restores rather than seeds.
- `var today: Range<Date> { calendar.day(containing: now)! }` — The day the feature computes at mount, by whatever calendar the test installed.
- `func makeStore(` — A mounted store on a clock the test controls; the mount sets the day, and restores whatever else the database says before anything else runs.
- `func block(_ event: String, on table: String, reason: String) async throws` — Makes the next writes of a kind fail, as a database might: a trigger raising an error.
- `func until<Value: Sendable>(_ fetch: Fetch<Value>, _ condition: @escaping @Sendable (Value) -> Bool) async throws` — Waits until an observed query reads as required. A query is one shared reader per request and database, so a fetch made here of the feature's request is the feature's own observation: when it reads as required here, the feature has been told. A real-time deadline fails the test rather than hang it.
- `for try await value in Observations({ fetch.wrappedValue }) where condition(value) { return }` — The sequence begins with the current value, so a query that already reads as required returns at once.
- `let draft = Reminder(id: Reminder.ID(UUID(0)), list: personal, created: now)` — From the home the plus opens the sheet (inside a list it edits a row in place).
- `await store.send(.destination(.reminder(.tagAdded("ADULTING"))))` — A tag that exists in another case attaches the existing tag, not a twin.
- `await store.send(.destination(.reminder(.saveButtonTapped))) { $0.destination = nil }?.value` — The sheet closes only once the write has landed.
- `try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }` — Another writer deletes a reminder: the home and the detail both follow.
- `#expect(try await stored(first)?.isBlank == true)` — The new row is in the database at once, blank, and shown in the detail.
- `#expect(try await stored(first)?.title == "")` — Typing writes nothing: the row in the database is still blank until editing ends.
- `await store.dismount()` — Quit without Done: the row being edited is in the database, as it was last written.
- `await revived.send(.filterTapped(.today))` — Leaving the detail, as the user, still ends the restored session.
- `await store.send(.detailEndReached) { $0.detailWindow = Reminder.Window(key: .all, rows: 2 * step) }?.value` — Near the end the next step is read; at the end nothing more is asked for.
- `await store.send(.listTapped(list)) { $0.filter = .list(list) }?.value` — Another filter starts at the first step again.
- `let id = Reminder.ID(UUID(0))` — A new row goes at the end of the list, so the whole list is read to show it.
- `await store.send(.doneButtonTapped)?.value` — Done, another row, and Details all keep the row open rather than lose the text.
- `await store.modify { $0[draft: groceries.id].notes = "Oat milk" }?.value` — A change to another field waits with the title; the row still holds the fixture.
- `try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }` — Another writer flags the reminder meanwhile; the commit keeps the flag and changes the title.
- `let reopened = try #require(saved)` — Deleted while its row is being edited: Done ends the session and recreates nothing.
- `await store.modify { $0[draft: groceries.id].title = "Late" }?.value` — A binding write after editing ended is dropped.
- `await store.modify { $0.search.text = "Take" } changes: { $0.search.text = "Take" }` — The typed text waits for a pause on the clock; the submit reads at once.
- `#expect(try await stored(groceries.id)?.completed == true)` — Eight seconds after the first tap nothing has completed: the second tap restarted the period.
- `await store.send(.reminderCompleteButtonTapped(doctor))?.value` — A reversed tap is not completed by a stale timer.
- `try await database.write { db in try Reminder.Record.toggle(doctor).execute(db) }` — A tap followed by a quit: the stored row still says completing, and the next mount finishes it.
- `try await block("UPDATE OF status", on: "reminders", reason: "status locked")` — A tap whose write fails is reported, and no timer runs for it.
- `await store.send(.reminderCompleteButtonTapped(groceries.id))?.value` — Rapid taps: the last change to the set is what the period is counted from.
- `await store.send(.reminderDeleted(groceries.id))?.value` — Deleting the reminder in its grace period ends its period: nothing is left to complete.
- `try await database.write { db in try Reminder.Record.toggle(haircut).execute(db) }` — Another writer starts a grace period: the feature sees it and completes it in time.
- `await store.send(.reminderCompleteButtonTapped(groceries.id))` — The tap lands in the draft of the row it is on, and starts the period.
- `await store.send(.reminderTapped(haircut.id)) { $0.editing = Reminder.Editing(haircut, session: UUID(1)) }?.value` — Another row opens while the period runs; when it ends, only the table changes.
- `let bread = try #require(await stored(row))` — The row reopens on the stored reminder, and leaving the detail ends the session.
- `await store.modify { $0[draft: row].title = "Late" }?.value` — A binding write after editing ended is dropped.
- `await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value` — Rapid row switching: each tap opens its own session on the stored row.
- `await store.modify` — Done while a save is under way is ignored: the writes are synchronous, so the state is put in that condition here, and nothing is written for the second tap.
- `#expect(await store.state.filter == .tags(["car"]))` — The detail narrows only once the tag is gone.
- `#expect(await store.state.failure == nil)` — The failures belong to the form: the app's own failure stays clear.
- `await store.modify { $0.search.tokens = [] } changes:` — Leaving search puts the completed toggle back.
- `let scale = Reminder.Sample.Scale(lists: 2, remindersPerList: 5, tags: 3)` — A generated seed remembers itself and clears the seeding flag once written.
- `try await TestExhaustivity.$current.withValue(.off)` — The message of a failed write is the database's; the save is asserted on its effects.
- `let draft = Reminder(id: Reminder.ID(UUID(2)), list: personal, title: "Orphan", created: now)` — A reminder whose list is deleted while its sheet is open cannot be saved: the draft stays.
- `await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value` — A stored reminder deleted while its sheet is open is not recreated by Done.
- `@Test(.dependencies` — The calendar, clock, and date are the test's own from the start, through the trait, so every task the feature runs sees them.
- `let day = tokyo.day(containing: start)!` — 2009-02-13 23:31:30 UTC is 08:31 on the 14th in Tokyo: the day is Tokyo's, whatever the process time zone.
- `let untilMidnight = day.upperBound.timeIntervalSince(start)` — Midnight, Tokyo time, with no write anywhere: the day, the count, and the detail move on.
- `await store.expect { $0.today = next }` — The task of a day change is the next midnight timer: it is not awaited, the dismount cancels it.
- `let later = start.addingTimeInterval(2.days)` — Coming back to the foreground days later reads the day again without waiting for the clock.
