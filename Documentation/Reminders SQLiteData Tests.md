# Reminders SQLiteData Tests

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Tests/Reminders SQLiteData Tests/Reminder SQLiteData Tests.swift

- `func makeDatabase() throws -> (database: DatabaseQueue, sample: Reminder.Sample)` — The sample in a fresh in-memory database.
- `try database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }` — Initialising again leaves a changed database alone; a reset does not.
- `try database.write { db in try List<Reminder>.Record.delete().execute(db) }` — An emptied but initialised database stays that way.
- `try database.write { db in try Reminder.Filter.Preference.Record.toggleShowCompleted(for: personal).execute(db) }` — The completed count is the whole filter's, not the window's, and is read only when they show.
- `try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .creationDate, for: personal).execute(db) }` — Creation Date: oldest first (the sample dates Groceries 30 days back, Buy concert tickets 1).
- `#expect(try self.detail(.all, database).rows.map(\.color).contains(sample.lists[2].color))` — Rows carry their own list's color, and a reminder reads back with its tags.
- `try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .dueDate, for: personal).execute(db) }` — Under due-date ordering a row with a date sorts first; the row being edited sorts by its place instead.
- `try database.write { db in try Reminder.Filter.Preference.Record.toggleShowCompleted(for: personal).execute(db) }` — With completed shown, the row moves among the completed at once, as the stock row does.
- `try database.write { db in` — Completed toggles back to incomplete; a reminder that is gone is untouched.
- `var renamed = sample.lists[1]` — An edit writes only what changed.
- `#expect(try database.write { db in try Tag<Reminder>.Record.add("Someday", in: db) } == "someday")` — Adding a tag that exists in another case is a no-op; attaching one attaches the known tag.
- `#expect(try database.write { db in try Tag<Reminder>.Record.rename("car", to: "Car", in: db) } == "Car")` — Renaming only in case keeps the tag and every link to it.
- `#expect(try database.write { db in try Tag<Reminder>.Record.rename("kids", to: "car", in: db) } == "Car")` — Merging: the links move to the target and the old tag goes.
- `let hidden = try results(Reminder.Search(text: "Take"), database)` — Without completed ones shown they are counted, not listed; sections follow the lists' order.
- `try database.write { db in` — Clear is scoped to the matches, keeps a reminder in its grace period, and honours the cutoff.
- `try database.write { db in try Reminder.Record.deleteCompleted(matching: Reminder.Search(text: "#so"), dueBefore: nil).execute(db) }` — A search that names no reminders deletes nothing.
- `try database.write { [today] db in try Reminder.Record.deleteCompleted(in: .completed, today: today).execute(db) }` — Clear in a filter takes the done reminders it shows and leaves the one in its grace period.
- `try database.write { db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }` — Another writer flags the reminder while a title edit is under way.
- `#expect(Reminder.Record.changes(from: stored!, to: stored!) == nil)` — An unchanged draft is no statement at all, and a status change is never a draft's to write.
- `#expect(try database.write { db in try Tag<Reminder>.Record.add("CAFÉ", in: db) } == "Café")` — Adding or attaching a case variant is the known tag, as SQLite's ASCII folding would not see.
- `#expect(try database.write { db in try Tag<Reminder>.Record.rename("Café", to: "CAFÉ", in: db) } == "CAFÉ")` — A case-only rename keeps the tag and its links; a rename onto a variant of another tag merges.
- `try #sql("INSERT INTO tags (title) VALUES ('Café'), ('CAFÉ'), ('car')").execute(db)` — Under NOCASE these were three tags; "car" and "CAR" were already one.
- `try database.write { db in try Tag<Reminder>.Record.delete("café").execute(db) }` — The rebuilt tables keep their constraints: a tag deleted takes its links.
- `try database.write { db in try Reminder.sample(at: now).replace(in: db) }` — Replacing again replaces, not appends.
- `let due = utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1))!` — A reminder due at 01:00 on the 14th UTC is due today in Tokyo (10:00 on the 14th, the same Tokyo day as now) and tomorrow in UTC.
- `let tomorrow = utc.day(containing: now.addingTimeInterval(.hour))!` — The day after, in UTC, it is today.
- `#expect(throws: (any Error).self)` — The rule is the table's: no writer can store a date the reader could not decode.
- `var configuration = Configuration()` — A database from before the rule: its malformed values are coerced, its rows all kept.
- `try old.write { db in try List<Reminder>.Record.find(list).delete().execute(db) }` — The rebuilt table keeps its cascade: deleting the list takes the reminders and their links.
- `func plan(_ statement: some Statement, _ database: some DatabaseWriter) throws -> [String]` — The steps of a statement's plan, as SQLite explains it.
- `@Test func `a row's tag list is read through the tags index, not a scan of the tags per row`() throws` — The tags key is collated as Swift compares; the join must compare it on the left, or the planner scans every tag for every row read (RESEARCH.md, scale investigation).
- `try database.write { db in _ = try Tag<Reminder>.Record.rename("someday", to: "Someday", in: db) }` — The titles still come from the tags table, in the case it stores them.
- `#expect(steps.contains { $0.contains("LIST SUBQUERY") }, "\(steps)")` — The tags that contain the text are one list (a LIST SUBQUERY), not a correlated scan per reminder.
- `#expect(try results(Reminder.Search(text: "SOMEDAY", showCompleted: true), database).reminders.map(\.title) == ["Haircut", "Groceries"])` — Matching by tag still finds the reminders that carry a matching tag, in any case.
- `let sql = "\(Reminder.Record.where { $0.matches(Reminder.Search(text: "day")) }.select(\.id).query)"` — The title and notes are matched from the folded column, not through the Swift function per row.
- `let groceries = try #require(try results(Reminder.Search(text: "oatmeal", showCompleted: true), database).reminders.first)` — The column follows the text: an edited title is found under its new words and not its old.
- `#expect(try overview(database).counts.today == 2)` — The range still means the same: undated reminders are not due, dated ones on the day are.
