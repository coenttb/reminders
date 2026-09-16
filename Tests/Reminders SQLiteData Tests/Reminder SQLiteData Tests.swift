import Foundation
import FoundationEssentials_Extensions
import Organizing
import Reminders
import Reminders_Application
import Reminders_SQLiteData
import SQLiteData
import Testing
import Tagged

@Suite struct `Reminder SQLite storage` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    var today: Range<Date> { calendar.day(containing: now)! }

    /// The sample in a fresh in-memory database.
    func makeDatabase() throws -> (database: DatabaseQueue, sample: Reminder.Sample) {
        let database = try Reminder.Schema.inMemoryDatabase()
        let sample = Reminder.sample(at: now)
        try database.write { db in try sample.replace(in: db) }
        return (database, sample)
    }

    func overview(_ database: some DatabaseWriter) throws -> Reminder.Overview {
        try database.read { db in try Reminder.Overview.Request(today: today).fetch(db) }
    }

    func detail(_ filter: Reminder.Filter, _ database: some DatabaseWriter, place: Reminder? = nil) throws -> Reminder.Filter.Detail {
        try #require(try database.read { db in try Reminder.Filter.Detail.Request(filter: filter, today: today, place: place).fetch(db) })
    }

    func results(_ search: Reminder.Search, _ database: some DatabaseWriter) throws -> Reminder.Search.Results {
        try database.read { db in try Reminder.Search.Results.Request(search: search).fetch(db) }
    }

    func stored(_ id: Reminder.ID, _ database: some DatabaseWriter) throws -> Reminder? {
        try database.read { db in try Reminder.Record.find(id).rows().fetchOne(db)?.value }
    }

    func count(_ database: some DatabaseWriter) throws -> Int {
        try database.read { db in try Reminder.Record.all.fetchCount(db) }
    }

    @Test func `the first run seeds the sample once, a later run leaves the database alone, and a reset replaces everything`() throws {
        let database = try Reminder.Schema.inMemoryDatabase()
        #expect(try database.read { db in try Reminder.Session.Record.state.fetchCount(db) } == 0)
        let sample = Reminder.sample(at: now)
        try database.write { db in
            try sample.initialize(in: db)
            try sample.initialize(in: db)
        }
        #expect(try database.read { db in try Reminder.Session.Record.state.fetchCount(db) } == 1)
        #expect(try overview(database).counts == Reminder.Filter.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        // Initialising again leaves a changed database alone; a reset does not.
        try database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        try database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).counts.all == 7)
        try database.write { db in try sample.replace(in: db) }
        #expect(try overview(database).counts.all == 8)
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == sample.reminders.reduce(0) { $0 + $1.tags.count })
        // An emptied but initialised database stays that way.
        try database.write { db in try List<Reminder>.Record.delete().execute(db) }
        try database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).lists.isEmpty)
    }

    @Test func `the home counts open reminders only and lists the tags in use`() throws {
        let (database, sample) = try makeDatabase()
        let overview = try overview(database)
        #expect(overview.counts == Reminder.Filter.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        #expect(overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(overview.lists.map(\.count) == [4, 2, 2])
        #expect(overview.usedTags.map(\.title) == ["adulting", "car", "kids", "night", "optional", "social", "someday"])
        #expect(overview.rankedTags.prefix(3).map(\.title) == ["social", "adulting", "optional"])
        try database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        #expect(try self.overview(database).lists.map(\.count) == [3, 2, 2])
    }

    @Test func `a detail filters by membership and orders by its preference`() throws {
        let (database, sample) = try makeDatabase()
        let personal = Reminder.Filter.list(sample.lists[0].id)
        var detail = try detail(personal, database)
        #expect(detail.filter == personal && detail.color == sample.lists[0].color)
        #expect(detail.reminders.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .priority, for: personal).execute(db) }
        detail = try self.detail(personal, database)
        #expect(detail.preference.ordering == .priority)
        #expect(detail.reminders.map(\.title) == ["Doctor appointment", "Haircut", "Groceries", "Buy concert tickets"])
        try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .title, for: personal).execute(db) }
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Buy concert tickets", "Doctor appointment", "Groceries", "Haircut"])
        // Creation Date: oldest first (the sample dates Groceries 30 days back, Buy concert tickets 1).
        try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .creationDate, for: personal).execute(db) }
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Groceries", "Haircut", "Doctor appointment", "Buy concert tickets"])
        try database.write { db in try Reminder.Filter.Preference.Record.toggleShowCompleted(for: personal).execute(db) }
        detail = try self.detail(personal, database)
        #expect(detail.preference.showCompleted && detail.reminders.map(\.title).last == "Take a walk")
        #expect(try self.detail(.completed, database).reminders.count == 3)
        #expect(try self.detail(.today, database).reminders.count == 2)
        #expect(try self.detail(.scheduled, database).reminders.count == 7)
        #expect(try self.detail(.flagged, database).reminders.map(\.title) == ["Haircut", "Pick up kids from school"])
        #expect(try self.detail(.tags(["social"]), database).reminders.map(\.title) == ["Buy concert tickets", "Prepare for WWDC"])
        #expect(try self.detail(.all, database).reminders.count == 8)
        // Rows carry their own list's color, and a reminder reads back with its tags.
        #expect(try self.detail(.all, database).rows.map(\.color).contains(sample.lists[2].color))
        #expect(try self.detail(personal, database).reminders.first { $0.title == "Groceries" }?.tags == ["someday", "optional", "adulting"])
    }

    @Test func `titles order case-insensitively and the row being edited keeps its place`() throws {
        let (database, sample) = try makeDatabase()
        let personal = Reminder.Filter.list(sample.lists[0].id)
        let groceries = sample.reminders[0]
        try database.write { db in
            try Reminder.Record.changes(from: groceries, to: { var r = groceries; r.title = "apples"; return r }())?.execute(db)
            try Reminder.Filter.Preference.Record.set(ordering: .title, for: personal).execute(db)
        }
        #expect(try detail(personal, database).reminders.map(\.title) == ["apples", "Buy concert tickets", "Doctor appointment", "Haircut"])
        // Under due-date ordering a row with a date sorts first; the row being edited sorts by its place instead.
        try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .dueDate, for: personal).execute(db) }
        var dated = groceries
        dated.title = "apples"
        dated.due = .day(now.addingTimeInterval(-400_000))
        try database.write { db in try Reminder.Record.changes(from: groceries, to: dated)?.execute(db) }
        #expect(try detail(personal, database).reminders.first?.id == groceries.id)
        #expect(try detail(personal, database, place: groceries).reminders.last?.id == groceries.id)
    }

    @Test func `a reminder in its grace period stays in place and counts as completed`() throws {
        let (database, sample) = try makeDatabase()
        let groceries = sample.reminders[0].id
        let personal = Reminder.Filter.list(sample.reminders[0].list)
        try database.write { db in try Reminder.Record.toggle(groceries).execute(db) }
        #expect(try stored(groceries, database)?.completed == true)
        #expect(try database.read { db in try Reminder.Completion.Pending.Request().fetch(db) } == [groceries])
        #expect(try overview(database).counts.all == 7)
        #expect(try detail(personal, database).reminders.last?.id == groceries)
        // With completed shown, the row moves among the completed at once, as the stock row does.
        try database.write { db in try Reminder.Filter.Preference.Record.toggleShowCompleted(for: personal).execute(db) }
        let haircut = sample.reminders[1].id
        let place = try detail(personal, database).reminders.map(\.id).firstIndex(of: haircut)
        try database.write { db in try Reminder.Record.toggle(haircut).execute(db) }
        let moved = try detail(personal, database).reminders.map(\.id)
        #expect(moved.firstIndex(of: haircut).map { $0 > (place ?? 0) } == true, "\(moved)")
        try database.write { db in
            try Reminder.Record.toggle(haircut).execute(db)
            try Reminder.Filter.Preference.Record.toggleShowCompleted(for: personal).execute(db)
        }
        try database.write { db in try Reminder.Record.toggle(groceries).execute(db) }
        #expect(try stored(groceries, database)?.completion == .incomplete)
        #expect(try database.read { db in try Reminder.Record.where { $0.isPending }.fetchCount(db) } == 0)
        try database.write { db in
            try Reminder.Record.toggle(groceries).execute(db)
            try Reminder.Record.completePending.execute(db)
        }
        #expect(try stored(groceries, database)?.completion == .completed)
        #expect(try database.read { db in try Reminder.Completion.Pending.Request().fetch(db) }.isEmpty)
        // Completed toggles back to incomplete; a reminder that is gone is untouched.
        try database.write { db in
            try Reminder.Record.toggle(groceries).execute(db)
            try Reminder.Record.toggle(Reminder.ID(UUID())).execute(db)
        }
        #expect(try stored(groceries, database)?.completion == .incomplete)
    }

    @Test func `deleting a list takes its reminders and the last one is replaced by the default`() throws {
        let (database, sample) = try makeDatabase()
        let business = sample.lists[2].id
        try database.write { db in try List<Reminder>.Record.delete(business, replacement: List<Reminder>.ID(UUID()), in: db) }
        #expect(try database.read { db in try Reminder.Record.where { $0.listID.eq(business) }.fetchCount(db) } == 0)
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == sample.reminders.filter { $0.list != business }.reduce(0) { $0 + $1.tags.count })
        let replacement = List<Reminder>.ID(UUID())
        try database.write { db in
            try List<Reminder>.Record.delete(sample.lists[0].id, replacement: List<Reminder>.ID(UUID()), in: db)
            try List<Reminder>.Record.delete(sample.lists[1].id, replacement: replacement, in: db)
        }
        let overview = try overview(database)
        #expect(overview.lists.map(\.list.title) == ["Personal"] && overview.lists.first?.id == replacement && overview.counts.all == 0)
    }

    @Test func `a new list takes the last position and lists move as SwiftUI moves them`() throws {
        let (database, sample) = try makeDatabase()
        let chores = List<Reminder>(id: List<Reminder>.ID(UUID()), title: "Chores")
        try database.write { db in
            try List<Reminder>.Record.insert { List<Reminder>.Record(chores) }.execute(db)
            try List<Reminder>.Record.placeLast(chores.id).execute(db)
        }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal", "Family", "Business", "Chores"])
        let before = try overview(database).lists.map(\.id)
        let ids = [before[1], before[2], before[0], before[3]]
        try database.write { db in try List<Reminder>.Record.reorder(ids).execute(db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Family", "Business", "Personal", "Chores"])
        // An edit writes only what changed.
        var renamed = sample.lists[1]
        renamed.title = "Home"
        try database.write { db in try List<Reminder>.Record.changes(from: sample.lists[1], to: renamed)?.execute(db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Home", "Business", "Personal", "Chores"])
        #expect(List<Reminder>.Record.changes(from: renamed, to: renamed) == nil)
    }

    @Test func `tags are shared, renamed everywhere, merged when renamed onto another, and deleted everywhere`() throws {
        let (database, sample) = try makeDatabase()
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("social", to: "friends", in: db) } == "friends")
        #expect(try detail(.tags(["friends"]), database).reminders.count == 2)
        #expect(try stored(sample.reminders[3].id, database)?.tags == ["car", "kids", "friends"])
        try database.write { db in try Tag<Reminder>.Record.delete("friends").execute(db) }
        #expect(try database.read { db in try Reminder.Tagging.where { $0.tagID.eq(Tag<Reminder>.ID("friends")) }.fetchCount(db) } == 0)
        // Adding a tag that exists in another case is a no-op; attaching one attaches the known tag.
        #expect(try database.write { db in try Tag<Reminder>.Record.add("Someday", in: db) } == "someday")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["CAR"])
        try database.write { db in
            try Reminder.Record.insert { Reminder.Record(wash) }.execute(db)
            try Reminder.Record.placeLast(wash.id).execute(db)
            try Reminder.Tagging.attach(wash.tags, to: wash.id, in: db)
        }
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        #expect(try stored(wash.id, database)?.tags == ["car"])
        #expect(try stored(wash.id, database)?.position == 11)
        // Renaming only in case keeps the tag and every link to it.
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("car", to: "Car", in: db) } == "Car")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Car"))
        #expect(try stored(wash.id, database)?.tags == ["Car"])
        #expect(try detail(.tags(["Car"]), database).reminders.map(\.title) == ["Wash"])
        #expect(try overview(database).usedTags.map(\.title) == ["adulting", "Car", "kids", "night", "optional", "someday"])
        // Merging: the links move to the target and the old tag goes.
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("kids", to: "car", in: db) } == "Car")
        #expect(try stored(sample.reminders[3].id, database)?.tags == ["Car"])
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 5)
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("nothing", to: "x", in: db) } == nil)
    }

    @Test func `tags rank by use and suggestions complete a prefix case-insensitively`() throws {
        let (database, _) = try makeDatabase()
        try database.write { db in
            _ = try Tag<Reminder>.Record.rename("car", to: "Car", in: db)
            try Tag<Reminder>.Record.add("Cat", in: db)
        }
        #expect(try overview(database).rankedTags.map(\.title) == ["social", "adulting", "optional", "someday", "Car", "kids", "night", "Cat"])
        #expect(try results(Reminder.Search(text: "#c"), database).suggestions.map(\.title) == ["Car", "Cat"])
        #expect(try results(Reminder.Search(text: "#so"), database).suggestions.map(\.title) == ["social", "someday"])
        #expect(try results(Reminder.Search(text: "#so", tokens: [.tag("social")]), database).suggestions.map(\.title) == ["someday"])
    }

    @Test func `search matches text and tag tokens and can clear completed matches`() throws {
        let (database, sample) = try makeDatabase()
        #expect(try results(Reminder.Search(text: "Take", showCompleted: true), database).reminders.map(\.title) == ["Take a walk", "Take out trash"])
        // Without completed ones shown they are counted, not listed; sections follow the lists' order.
        let hidden = try results(Reminder.Search(text: "Take"), database)
        #expect(hidden.reminders.map(\.title) == ["Take out trash"] && hidden.completedCount == 1)
        #expect(hidden.sections.map(\.list.title) == ["Family"])
        #expect(try results(Reminder.Search(text: "Take", tokens: [.tag("car")], showCompleted: true), database).reminders.map(\.title) == ["Take a walk"])
        #expect(try results(Reminder.Search(tokens: [.near("Take"), .near("walk")], showCompleted: true), database).reminders.map(\.title) == ["Take a walk"])
        #expect(try results(Reminder.Search(text: "oatmeal"), database).reminders.map(\.title) == ["Groceries"])
        #expect(try results(Reminder.Search(text: "ADULT"), database).reminders.map(\.title) == ["Doctor appointment", "Groceries"])
        #expect(try results(Reminder.Search(text: "payroll"), database).reminders.map(\.title) == ["Call accountant"])
        #expect(try results(Reminder.Search(text: "#so"), database).reminders.isEmpty)
        #expect(try results(Reminder.Search(), database).reminders.isEmpty)
        // Clear is scoped to the matches, keeps a reminder in its grace period, and honours the cutoff.
        try database.write { db in
            try Reminder.Record.toggle(sample.reminders[7].id).execute(db)
            try Reminder.Record.deleteCompleted(matching: Reminder.Search(text: "Take"), dueBefore: calendar.date(byAdding: .month, value: -12, to: now)).execute(db)
        }
        #expect(try overview(database).counts.all == 7)
        #expect(try count(database) == 11)
        try database.write { db in
            try Reminder.Record.deleteCompleted(matching: Reminder.Search(text: "Take"), dueBefore: calendar.date(byAdding: .month, value: -1, to: now)).execute(db)
        }
        #expect(try count(database) == 10)
        #expect(try database.read { db in try Reminder.Completion.Pending.Request().fetch(db) }.contains(sample.reminders[7].id))
        #expect(try detail(.completed, database).reminders.map(\.title) == ["Get laundry", "Send weekly emails", "Take out trash"])
        // A search that names no reminders deletes nothing.
        try database.write { db in try Reminder.Record.deleteCompleted(matching: Reminder.Search(text: "#so"), dueBefore: nil).execute(db) }
        #expect(try count(database) == 10)
        // Clear in a filter takes the done reminders it shows and leaves the one in its grace period.
        try database.write { [today] db in try Reminder.Record.deleteCompleted(in: .completed, today: today).execute(db) }
        #expect(try count(database) == 8)
        #expect(try detail(.completed, database).reminders.map(\.title) == ["Take out trash"])
    }

    @Test func `a draft updates only edited fields and leaves completion to the timer`() throws {
        let (database, sample) = try makeDatabase()
        let groceries = sample.reminders[0]
        // Another writer flags the reminder while a title edit is under way.
        try database.write { db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }
        var draft = groceries
        draft.title = "Groceries and more"
        draft.tags.insert("fresh")
        draft.tags.remove("optional")
        try database.write { db in
            try Reminder.Record.changes(from: groceries, to: draft)?.execute(db)
            try Reminder.Tagging.detach(groceries.tags.subtracting(draft.tags), from: groceries.id).execute(db)
            try Reminder.Tagging.attach(draft.tags.subtracting(groceries.tags), to: groceries.id, in: db)
        }
        let stored = try stored(groceries.id, database)
        #expect(stored?.title == "Groceries and more" && stored?.flagged == true && stored?.tags == ["someday", "adulting", "fresh"])
        #expect(try self.stored(sample.reminders[1].id, database) == sample.reminders[1])
        // An unchanged draft is no statement at all, and a status change is never a draft's to write.
        #expect(Reminder.Record.changes(from: stored!, to: stored!) == nil)
        var completed = stored!
        completed.completion = .completed
        #expect(Reminder.Record.changes(from: stored!, to: completed) == nil)

    }

    @Test func `a row continues beneath its anchor and moves keep the positions they were given`() throws {
        let (database, sample) = try makeDatabase()
        let haircut = sample.reminders[1]
        let next = Reminder(id: Reminder.ID(UUID()), list: haircut.list, position: haircut.position + 1)
        try database.write { db in
            try Reminder.Record.makeRoom(after: haircut.position).execute(db)
            try Reminder.Record.insert { Reminder.Record(next) }.execute(db)
        }
        #expect(try stored(sample.reminders[2].id, database)?.position == 3)
        let personal = Reminder.Filter.list(sample.lists[0].id)
        try database.write { db in try Reminder.Filter.Preference.Record.set(ordering: .manual, for: personal).execute(db) }
        #expect(try detail(personal, database, place: { var p = haircut; p.id = next.id; p.position = next.position; return p }()).reminders.map(\.id).prefix(3) == [sample.reminders[0].id, haircut.id, next.id])
        var ids = try detail(personal, database).reminders.map(\.id)
        ids.swapAt(0, 2)
        try database.write { db in try Reminder.Record.reorder(ids, in: db) }
        #expect(try detail(personal, database).reminders.map(\.id) == ids)
        #expect(try stored(next.id, database)?.position == 0)
    }

    @Test func `a preference for an unknown detail is ignored and each setter touches its own column`() throws {
        let (database, sample) = try makeDatabase()
        try database.write { db in
            try Reminder.Filter.Preference.Record.insert { Reminder.Filter.Preference.Record(key: Reminder.Filter.Key(rawValue: "nothing"), Reminder.Filter.Preference(ordering: .title)) }.execute(db)
        }
        #expect(try detail(.list(sample.lists[0].id), database).preference == Reminder.Filter.Preference())
        #expect(try detail(.completed, database).preference == Reminder.Filter.Preference(showCompleted: true))
        try database.write { db in
            try Reminder.Filter.Preference.Record.toggleShowCompleted(for: .completed).execute(db)
            try Reminder.Filter.Preference.Record.set(ordering: .title, for: .completed).execute(db)
            try Reminder.Filter.Preference.Record.toggleShowCompleted(for: .completed).execute(db)
        }
        #expect(try detail(.completed, database).preference == Reminder.Filter.Preference(ordering: .title, showCompleted: true))
    }

    @Test func `a tag is one tag in any case, including beyond ASCII, and links follow a rename`() throws {
        let (database, sample) = try makeDatabase()
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["Café"])
        try database.write { db in
            try Reminder.Record.insert { Reminder.Record(wash) }.execute(db)
            try Reminder.Tagging.attach(wash.tags, to: wash.id, in: db)
        }
        // Adding or attaching a case variant is the known tag, as SQLite's ASCII folding would not see.
        #expect(try database.write { db in try Tag<Reminder>.Record.add("CAFÉ", in: db) } == "Café")
        #expect(try database.write { db in try Tag<Reminder>.Record.add("café", in: db) } == "Café")
        try database.write { db in try Reminder.Tagging.attach(["CAFÉ"], to: sample.reminders[0].id, in: db) }
        #expect(try stored(sample.reminders[0].id, database)?.tags.contains("Café") == true)
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.filter { $0.lowercased() == "café" } == ["Café"])
        #expect(try detail(.tags(["Café"]), database).reminders.count == 2)
        // A case-only rename keeps the tag and its links; a rename onto a variant of another tag merges.
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("Café", to: "CAFÉ", in: db) } == "CAFÉ")
        #expect(try stored(wash.id, database)?.tags == ["CAFÉ"])
        #expect(try detail(.tags(["CAFÉ"]), database).reminders.count == 2)
        try database.write { db in try Tag<Reminder>.Record.add("Straße", in: db) }
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("Straße", to: "café", in: db) } == "CAFÉ")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Straße") == false)
    }

    @Test func `upgrading a database keeps its records and folds tags that were twins under ASCII rules`() throws {
        var configuration = Configuration()
        Reminder.Schema.prepare(&configuration)
        let database = try DatabaseQueue(configuration: configuration)
        try Reminder.Schema.migrate(database, upTo: "Create the Reminders tables")
        let list = List<Reminder>.ID(UUID())
        let (first, second) = (Reminder.ID(UUID()), Reminder.ID(UUID()))
        try database.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(first), \(list), 'Bread')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(second), \(list), 'Milk')").execute(db)
            // Under NOCASE these were three tags; "car" and "CAR" were already one.
            try #sql("INSERT INTO tags (title) VALUES ('Café'), ('CAFÉ'), ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(first), 'Café'), (\(first), 'CAFÉ'), (\(second), 'CAFÉ'), (\(second), 'car')").execute(db)
        }
        try Reminder.Schema.migrate(database)
        let titles = try database.read { db in try Tag<Reminder>.Record.all.order(by: \.title).fetchAll(db).map(\.title) }
        #expect(titles == ["Café", "car"])
        #expect(try stored(first, database)?.tags == ["Café"])
        #expect(try stored(second, database)?.tags == ["Café", "car"])
        #expect(try stored(first, database)?.title == "Bread")
        #expect(try stored(first, database)?.created == Date(timeIntervalSince1970: 0))
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == 3)
        // The rebuilt tables keep their constraints: a tag deleted takes its links.
        try database.write { db in try Tag<Reminder>.Record.delete("café").execute(db) }
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == 1)
        try Reminder.Schema.migrate(database)
    }

    @Test func `a generated sample at scale is written in one transaction and read back whole`() throws {
        let database = try Reminder.Schema.inMemoryDatabase()
        let sample = Reminder.Sample.generated(.medium, seed: 1, at: now, calendar: calendar)
        try database.write { db in try sample.replace(in: db) }
        #expect(try database.read { db in try Reminder.Record.all.fetchCount(db) } == 1_000)
        #expect(try database.read { db in try List<Reminder>.Record.all.fetchCount(db) } == 10)
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 30)
        let links = sample.reminders.reduce(0) { $0 + $1.tags.count }
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == links)
        let first = try #require(sample.reminders.first)
        #expect(try stored(first.id, database) == first)
        #expect(try overview(database).lists.count == 10)
        #expect(try overview(database).counts.all == sample.reminders.count { !$0.completed })
        // Replacing again replaces, not appends.
        try database.write { db in try Reminder.sample(at: now).replace(in: db) }
        #expect(try database.read { db in try Reminder.Record.all.fetchCount(db) } == 11)
    }

    @Test func `today is decided by the calendar's day, not the process time zone`() throws {
        let (database, sample) = try makeDatabase()
        let utc = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        // A reminder due at 01:00 on the 14th UTC is due today in Tokyo (10:00 on the 14th, the same
        // Tokyo day as now) and tomorrow in UTC.
        let due = utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1))!
        let late = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Late", due: .day(due))
        try database.write { db in
            try Reminder.Record.delete().execute(db)
            try Reminder.Record.insert { Reminder.Record(late) }.execute(db)
        }
        func today(_ calendar: Calendar) throws -> [String] {
            try database.read { db in
                try Reminder.Filter.Detail.Request(filter: .today, today: calendar.day(containing: now)!).fetch(db)?.reminders.map(\.title) ?? []
            }
        }
        func count(_ calendar: Calendar) throws -> Int {
            try database.read { db in try Reminder.Overview.Request(today: calendar.day(containing: now)!).fetch(db).counts.today }
        }
        #expect(try today(utc) == [] && count(utc) == 0)
        #expect(try today(tokyo) == ["Late"] && count(tokyo) == 1)
        // The day after, in UTC, it is today.
        let tomorrow = utc.day(containing: now.addingTimeInterval(.hour))!
        #expect(try database.read { db in try Reminder.Overview.Request(today: tomorrow).fetch(db).counts.today } == 1)
    }

    @Test func `a row that could not be read is refused by the schema, and one stored before the rule is brought back inside it`() throws {
        let (database, sample) = try makeDatabase()
        // The rule is the table's: no writer can store a date the reader could not decode.
        #expect(throws: (any Error).self) {
            try database.write { db in try #sql("UPDATE reminders SET due = 'garbage' WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        #expect(throws: (any Error).self) {
            try database.write { db in try #sql("UPDATE reminders SET status = 7 WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        #expect(try detail(.all, database).reminders.count == 8)
        // A database from before the rule: its malformed values are coerced, its rows all kept.
        var configuration = Configuration()
        Reminder.Schema.prepare(&configuration)
        let old = try DatabaseQueue(configuration: configuration)
        try Reminder.Schema.migrate(old, upTo: "Compare tag titles as Swift does")
        let list = List<Reminder>.ID(UUID())
        let (bad, good) = (Reminder.ID(UUID()), Reminder.ID(UUID()))
        try old.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title, due, status, priority) VALUES (\(bad), \(list), 'Bad', 'garbage', 9, 4)").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title, due, status, priority) VALUES (\(good), \(list), 'Good', '2026-09-15 10:00:00.000', 2, 3)").execute(db)
            try #sql("INSERT INTO tags (title) VALUES ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(bad), 'car')").execute(db)
        }
        try Reminder.Schema.migrate(old)
        let repaired = try old.read { db in try Reminder.Record.find(bad).rows().fetchOne(db)?.value }
        #expect(repaired?.due == nil && repaired?.completion == .incomplete && repaired?.priority == nil && repaired?.tags == ["car"])
        let kept = try old.read { db in try Reminder.Record.find(good).rows().fetchOne(db)?.value }
        #expect(kept?.completed == true && kept?.priority == .high && kept?.due != nil)
        #expect(try old.read { db in try Reminder.Completion.Pending.Request().fetch(db) } == [good])
        // The rebuilt table keeps its cascade: deleting the list takes the reminders and their links.
        try old.write { db in try List<Reminder>.Record.find(list).delete().execute(db) }
        #expect(try old.read { db in try Reminder.Tagging.all.fetchCount(db) } == 0)
    }

    @Test func `filters round-trip through their keys and colors through their hex`() {
        let id = List<Reminder>.ID(UUID())
        for filter in [Reminder.Filter.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Reminder.Filter(key: filter.key) == filter)
            #expect(filter.key.filter == filter)
        }
        #expect(Reminder.Filter.tags(["b", "a"]).key == Reminder.Filter.tags(["a", "b"]).key)
        #expect(Reminder.Filter.list(id).key.rawValue == "list_\(id.rawValue.uuidString)")
        #expect(Reminder.Filter(key: Reminder.Filter.Key(rawValue: "list_not-a-uuid")) == nil)
        #expect(Color.Hex(rawValue: 0x4a99ef).color == .default && Color.Hex(.default).rawValue == 0x4a99ef)
        #expect(Color.Hex(Color(red: 2, green: -1, blue: 0.5)).rawValue == 0xff0080)
    }
}
