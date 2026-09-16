# Reminders SQLiteData

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Sources/Reminders SQLiteData/Color.Hex.swift

- `public struct Hex: RawRepresentable, Hashable, Sendable, QueryBindable` — A color as the integer `0xRRGGBB` the lists table stores.

## Sources/Reminders SQLiteData/List.Record+Statements.swift

- `public static func placeLast(_ id: List<Reminder>.ID) -> UpdateOf<List<Reminder>.Record>` — Puts a list at the end of the user's order.
- `public static func changes(from original: List<Reminder>, to draft: List<Reminder>) -> UpdateOf<List<Reminder>.Record>?` — The columns an edit changed, and nothing else; nil when no column differs.
- `public static func delete(_ id: List<Reminder>.ID, replacement: List<Reminder>.ID, in db: Database) throws` — Removes the list; its reminders go with it by the foreign key. When it was the last one, the default list takes its place under the given identifier.
- `public static func reorder(_ ids: [List<Reminder>.ID]) -> UpdateOf<List<Reminder>.Record>` — Reorders the lists as the user dragged them: each takes the position of its place in the order.

## Sources/Reminders SQLiteData/List.Record.swift

- `@Table("lists")` — The stored form of a list; the color is its `0xRRGGBB` integer. The table is this app's, so the record is declared for its element only; `@Table` cannot expand under a phantom generic anyway.

## Sources/Reminders SQLiteData/Reminder.Completion.Pending.Request.swift

- `public struct Request: FetchKeyRequest` — Reads which reminders are in their grace period, and again whenever that changes, so the grace timer follows the table however a reminder came to be pending.

## Sources/Reminders SQLiteData/Reminder.Filter.Detail.Request.swift

- `public struct Request: FetchKeyRequest` — Reads one filter in one transaction: its preference decides the query, so a change to the preference re-reads the rows along with it. The rows are the first `limit` in the preference's order, with the count of all of them; no limit reads them all. No filter reads nothing.
- `public var today: Range<Date>` — The day the Today filter shows.
- `public var place: Reminder?` — The row being edited sorts by this value until editing ends.

## Sources/Reminders SQLiteData/Reminder.Filter.Key.swift

- `public struct Key: RawRepresentable, Hashable, Sendable, QueryBindable` — The stored form of a filter, also the key preferences are stored under: a smart group's name, `list_` and the list's identifier, or `tags_` and the tag titles. Tag titles are free text, so they are joined by the unit separator, and sorted so the same set of tags shares one key whatever order it was opened in.
- `public var filter: Reminder.Filter? { Reminder.Filter(key: self) }` — The filter the key names, if it names one.

## Sources/Reminders SQLiteData/Reminder.Filter.Preference.Record.swift

- `@Table("preferences")` — One row per filter the user adjusted, keyed by the filter's stored form.
- `public static func preference(for filter: Reminder.Filter) -> Where<Reminder.Filter.Preference.Record>` — The preference a filter has, or its default when none was stored.
- `public static func set(ordering: Reminder.Ordering, for filter: Reminder.Filter) -> InsertOf<Reminder.Filter.Preference.Record>` — Sets a filter's ordering, leaving show-completed as it is (or at its default for a filter never adjusted).
- `public static func toggleShowCompleted(for filter: Reminder.Filter) -> InsertOf<Reminder.Filter.Preference.Record>` — Flips a filter's show-completed, leaving the ordering as it is.

## Sources/Reminders SQLiteData/Reminder.Overview.Request.swift

- `public struct Request: FetchKeyRequest` — Reads the overview in one transaction, and again whenever a table it reads changes.
- `public var today: Range<Date>` — The day the Today count is taken over.

## Sources/Reminders SQLiteData/Reminder.Record+Queries.swift

- `public var isCompleted: some QueryExpression<Bool>` — Pending counts as completed everywhere but the grace timer.
- `public var isDone: some QueryExpression<Bool>` — Fully completed: the grace period is over.
- `public func isDue(during day: Range<Date>) -> some QueryExpression<Bool>` — Incomplete and due within a day's bounds; the bounds come from the app's calendar, so the database has no say in where a day starts. Written as a plain range so the index on the due date serves it; a `coalesce` around the comparison would defeat it.
- `public func belongs(to filter: Reminder.Filter, today: Range<Date>) -> SQLQueryExpression<Bool>` — Whether the reminder belongs to a filter; `today` is the day the filter of that name shows.
- `fileprivate func matches(_ text: String) -> some QueryExpression<Bool>` — Whether the title, notes, or a tag contains the text, case-insensitively as Swift compares. The title and notes are compared folded, from the column the schema keeps for the search. The tags that contain the text are found once, from the tags table, and the reminder's links are then looked up in their index: a link-by-link comparison ran the Swift function for every link of every reminder (RESEARCH.md, device measurement).
- `fileprivate func carries(_ tag: Tag<Reminder>.ID) -> some QueryExpression<Bool>` — Whether the reminder carries the tag.
- `public func matches(_ search: Reminder.Search) -> SQLQueryExpression<Bool>` — Whether the reminder matches every term of a search; a search that names no reminders (nothing typed, or a tag prefix alone) matches none.
- `public var tagList: some QueryExpression<String?>` — The tags the reminder carries, joined by the unit separator, in tag order; the titles are read from the tags table, so the case the tag is stored in is what a reminder shows. The tags key is compared on the left: SQLite takes the left operand's collation, and only under the key's own collation can its index serve the join. The other way round the planner scans every tag for every row (RESEARCH.md, scale investigation).
- `fileprivate func placed<Value>(` — The value a column sorts by: the reminder's own, or the place's for the row being edited, so that row keeps the place it had when editing began.
- `public func ordered(by ordering: Reminder.Ordering, showCompleted: Bool, placing place: Reminder? = nil) -> SQLQueryExpression<Bool>` — The ordering a preference asks for, ties broken by position as the manual order has it. Completed reminders sort last only when the filter shows them, and one in its grace period moves down with them at once, as the stock row does (Evidence/Parity/completion); hidden, it keeps its place until the period ends so the tap can be undone.
- `var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }` — The tag's title as the text column it is stored in.

## Sources/Reminders SQLiteData/Reminder.Record+Statements.swift

- `@Selection` — A reminder with its tags and its list's color, as the screens read it.
- `public static var rows: Select<Row, Reminder.Record, List<Reminder>.Record>` — Every reminder as a `Row`, joined to its list; narrow with `where`, `find`, and `order` before selecting, or apply them to the rows through the two-table closures.
- `public static func toggle(_ id: Reminder.ID) -> UpdateOf<Reminder.Record>` — The circle tap: incomplete starts the grace period; pending or completed reverts to incomplete.
- `public static var completePending: UpdateOf<Reminder.Record>` — The grace timer elapsed: every reminder still pending is now completed. One that was reverted meanwhile is incomplete and untouched; one deleted meanwhile is simply absent.
- `public static func placeLast(_ id: Reminder.ID) -> UpdateOf<Reminder.Record>` — Puts a reminder at the end of the manual order.
- `public static func makeRoom(after position: Int) -> UpdateOf<Reminder.Record>` — Moves every reminder after a position down one place, so a row can be inserted directly beneath it.
- `public static func reorder(_ ids: [Reminder.ID], in db: Database) throws` — Reorders the reminders as the user dragged them: the positions those reminders hold are dealt out again in the new order, so the rest of the manual order is untouched.
- `public static func changes(from original: Reminder, to draft: Reminder) -> UpdateOf<Reminder.Record>?` — The columns an edit changed, and nothing else, so a change made elsewhere to another field survives; nil when no column differs. The completion is the grace timer's, never a draft's, and the tags are links: see `Reminder.Tagging.attach` and `detach`.
- `public static func deleteCompleted(in filter: Reminder.Filter, today: Range<Date>) -> DeleteOf<Reminder.Record>` — Deletes the completed reminders a search matches, optionally only those due before a cutoff. One still in its grace period is kept, so the tap can be undone. Clear, in a filter that shows its completed reminders: every done reminder it contains.
- `public func rows() -> Select<Reminder.Record.Row, Reminder.Record, List<Reminder>.Record>` — The reminders as rows with their tags and list color.
- `public func rows() -> Select<Reminder.Record.Row, Reminder.Record, List<Reminder>.Record>` — The reminders as rows with their tags and list color.
- `public static func attach(_ tags: Set<Tag<Reminder>.ID>, to id: Reminder.ID, in db: Database) throws` — Links a reminder to tags by title. A title the tags table knows in another case attaches the known tag rather than a twin; an unknown one is created.
- `public static func detach(_ tags: Set<Tag<Reminder>.ID>, from id: Reminder.ID) -> DeleteOf<Reminder.Tagging>` — Unlinks tags from a reminder; the tags themselves stay.

## Sources/Reminders SQLiteData/Reminder.Record.swift

- `@Table("reminders")` — The stored form of a reminder; tags are rows of `Reminder.Tagging`. A due date is the `due` and `hasTime` columns. The `status` column encodes the completion together with the grace period: 0 incomplete, 1 completed, 2 completed but pending, so a database from before the grace period left the domain reads unchanged; the pending members are read through `Reminder.Completion.Pending.Request`.
- `@Table("remindersTags")` — One reminder-to-tag link; the many-to-many the domain expresses as `Reminder.tags`. The pair is the key, so there is no surrogate to grow.
- `static func completion(_ status: Int) -> Reminder.Completion` — Pending counts as completed everywhere but the grace timer.

## Sources/Reminders SQLiteData/Reminder.Search.Results.Request.swift

- `public struct Request: FetchKeyRequest` — Reads the search in one transaction: the first `limit` matches under their lists with the count of all of them, how many are completed whether or not they are shown, and the tags completing a typed prefix. No limit reads every match.
- `guard search.matchesReminders || search.tagPrefix != nil else { return results }` — Nothing typed reads nothing: an idle search is not re-read on every write.
- `let (matched, completed) = try Reminder.Record` — One pass counts the matches and the completed among them; the text rule is a Swift function run for every row, so each pass over the table is what the search costs.

## Sources/Reminders SQLiteData/Reminder.Session.Record.swift

- `@Table("session")` — One row holding which filter is open and which reminder is being edited in place.
- `public static var state: Where<Reminder.Session.Record> { Reminder.Session.Record.find(1) }` — The one row holding the open filter and the row being edited.

## Sources/Reminders SQLiteData/Schema.swift

- `public enum Schema {}` — The Reminders database: its tables, the connection setup they need, and the sample that fills a first run.
- `public static func migrate(_ database: some DatabaseWriter, upTo target: String? = nil) throws` — Creates the Reminders schema in any database, or brings an older one up to date; shared by the applications and a future server. `upTo` stops at an earlier migration, for tests that upgrade from it.
- `migrator.registerMigration("Compare tag titles as Swift does") { db in` — A tag's title is its key case-insensitively as Swift compares, not as SQLite's NOCASE folds ASCII: "Café" and "CAFÉ" are one tag. The table is rebuilt on the collation the connection installs; titles that were two tags and are now one keep the older, and the links follow it. The links are rebuilt too, so two links become one.
- `migrator.registerMigration("Constrain what a reminder row may hold") { db in` — The database is the source of truth, so what a row may hold is the schema's rule, not the reader's tolerance: a due date is stored text in one format, a status is one of the three, a priority one of the three or none. A writer that breaks the rule is refused; rows that broke it before the rule existed are brought back inside it (a malformed date is no date, an unknown status is incomplete, an unknown priority none) rather than left to fail every read of their screen.
- `migrator.registerMigration("Record when a reminder was created") { db in` — The Creation Date ordering needs a timestamp. Rows from before the column are dated at the epoch, so among themselves they keep the manual order.
- `migrator.registerMigration("Index the due date and the status") { db in` — The smart lists and the grace timer filter by these; without the indexes Today and the pending set scan every reminder (RESEARCH.md, scale investigation).
- `migrator.registerMigration("Keep the folded text for the search") { db in` — The search compared every title and notes through a Swift function, twice per read at 100,000 rows (RESEARCH.md, device measurement). The folded text is kept in a column the triggers maintain, and matched with SQLite's `instr`.
- `public static func prepare(_ configuration: inout Configuration)` — The connection setup every Reminders database needs: foreign keys, so a list takes its reminders with it, and the Swift text rules the queries call on. The tags table's key is declared on the `localizedCaseInsensitive` collation, so a connection without it cannot use that table: every Reminders database is opened through here.
- `public static func inMemoryDatabase() throws -> DatabaseQueue` — An in-memory database with the schema, for tests.
- `public static func initialize(with sample: Self, in db: Database) throws` — The first run: fills an uninitialised database with the sample. The state row is written by the first initialisation and never deleted, so a database initialised before is left alone whatever it holds, and a failed read throws rather than counting as a first run.
- `public static func replace(with sample: Self, in db: Database) throws` — The explicit reset: everything the database holds is replaced by the sample, in one transaction.
- `for lists in sample.lists.chunks(of: 200)` — Rows go in by the few hundred: a generated sample has a hundred thousand reminders, and one statement per row was the whole seeding time.
- `let taggings = sample.reminders.flatMap { reminder in reminder.tags.sorted().map { Reminder.Tagging(reminderID: reminder.id, tagID: $0) } }` — A sample's tags are canonical by construction, so the links need no title lookup.
- `fileprivate func chunks(of size: Int) -> [SubSequence]` — Consecutive slices of at most `size` elements.

## Sources/Reminders SQLiteData/Tag.Record+Statements.swift

- `public static func canonical(_ title: String) -> Select<String, Tag<Reminder>.Record, ()>` — The title the tags table already uses for a title in any case; the key compares as Swift's `localizedCaseInsensitiveCompare` does, so this is the one every path that attaches a tag must use.
- `@discardableResult` — Adds a tag, or finds the one the title already names in any case. Returns its identifier, or nil for an empty title.
- `public static func delete(_ id: Tag<Reminder>.ID) -> DeleteOf<Tag<Reminder>.Record>` — Removes the tag from every reminder that carries it, and then itself.
- `public static func rename(_ id: Tag<Reminder>.ID, to title: String, in db: Database) throws -> Tag<Reminder>.ID?` — Renames a tag everywhere it is used. Renaming onto a title another tag already has, in any case, merges into that tag; renaming only in case keeps the tag and its links. Returns the identifier the tag has afterwards, or nil when the tag is gone or the title empty.
- `let current: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: stored)` — Tagged also offers a failable `init?(_:)` from `LosslessStringConvertible`; the annotation picks the plain one.
- `try Reminder.Tagging.where { $0.tagID.eq(current) }.update { $0.tagID = renamed }.execute(db)` — The key compares case-insensitively, so a change of case alone does not cascade to the links.

## Sources/Reminders SQLiteData/Tag.Record.swift

- `@Table("tags")` — The stored form of a tag: its title is the key, case-insensitively as Swift compares.

## Sources/Reminders SQLiteData/TextRules.swift

- `@DatabaseFunction(isDeterministic: true)` — Whether the text contains the query as Swift's `localizedCaseInsensitiveContains` sees it; SQLite's `LIKE` folds only ASCII case.
- `@DatabaseFunction(isDeterministic: true)` — The text as the search stores and compares it: lowercased as Swift's `lowercased()` does. A reminder's title and notes are kept folded in a column, so a search compares them with SQLite's own `instr` rather than calling a Swift function for every row.
- `@DatabaseFunction(isDeterministic: true)` — Whether the text starts with the prefix, ignoring case as Swift's `lowercased()` does.
- `@DatabaseCollation` — Titles order as Swift's `localizedCaseInsensitiveCompare` orders them.
