import Foundation
import FoundationEssentials_Extensions
import Models
import Reminder
import Reminders
import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
import SQLiteData
import Testing
import Tagged

@Suite struct `Reminder SQLite storage` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    var today: Range<Date> { calendar.day(containing: now)! }

    func makeDatabase() throws -> (database: any DatabaseWriter, sample: Reminders.Sample) {
        let database = try Reminders.Schema.database()
        let sample = Reminders.sample(at: now)
        try database.write { db in try sample.replace(in: db) }
        return (database, sample)
    }

    func overview(_ database: some DatabaseWriter) throws -> Reminders.Summary {
        try database.read { db in try Reminders.Summary.Query(today: today).fetch(db) }
    }

    func detail(_ filter: Reminders.Filter, _ database: some DatabaseWriter, including: Reminders.Placement? = nil, limit: Int? = nil) throws -> Reminders.Page {
        try database.read { db in try Reminders.Page.Query(.filter(filter), today: today, including: including, limit: limit).fetch(db) }
    }

    func preference(_ filter: Reminders.Filter, _ database: some DatabaseWriter) throws -> Reminders.Preference {
        try database.read { db in try Reminders.Preference.Query(for: filter).fetch(db) }
    }

    func results(_ query: Reminders.Query, _ database: some DatabaseWriter, limit: Int? = nil) throws -> Reminders.Page {
        try database.read { db in try Reminders.Page.Query(.search(query), today: today, including: nil, limit: limit).fetch(db) }
    }

    func suggestions(_ prefix: String, excluding: Set<Models.Tag<Reminder>> = [], _ database: some DatabaseWriter) throws -> [Models.Tag<Reminder>] {
        try database.read { db in try Reminders.Tags.Query(prefix: prefix, excluding: excluding).fetch(db) }
    }

    func stored(_ id: Reminder.ID, _ database: some DatabaseWriter) throws -> Reminder? {
        try database.read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init) }
    }

    func position(_ id: Reminder.ID, _ database: some DatabaseWriter) throws -> Int? {
        try database.read { db in try Reminder.Record.find(id).select(\.position).fetchOne(db) }
    }

    func count(_ database: some DatabaseWriter) throws -> Int {
        try database.read { db in try Reminder.Record.all.fetchCount(db) }
    }

    @Test func `an empty database is installed with one list, and installing again changes nothing`() throws {
        let database = try Reminders.Schema.database()
        #expect(try database.read { db in try db.tableExists("session") } == false)
        let personal = Models.List<Reminder>.ID(UUID())
        try database.write { db in try Reminders.Schema.install(db, default: personal) }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal"] && overview(database).lists.first?.id == personal)
        try database.write { db in try Reminders.Schema.install(db, default: Models.List<Reminder>.ID(UUID())) }
        #expect(try overview(database).lists.map(\.id) == [personal])
        try database.write { db in try Reminders.sample(at: now).initialize(in: db) }
        #expect(try overview(database).lists.map(\.id) == [personal])
    }

    @Test func `the sample is written into an empty database once, a later run leaves the database alone, and a reset replaces everything`() throws {
        let database = try Reminders.Schema.database()
        let sample = Reminders.sample(at: now)
        try database.write { db in
            try sample.initialize(in: db)
            try sample.initialize(in: db)
        }
        #expect(try overview(database).counts == Reminders.Summary.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        try database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        try database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).counts.all == 7)
        try database.write { db in try sample.replace(in: db) }
        #expect(try overview(database).counts.all == 8)
        #expect(try database.read { db in try Reminders.Tagging.all.fetchCount(db) } == sample.reminders.reduce(0) { $0 + $1.tags.count })
        try database.write { db in try Models.List<Reminder>.Record.delete().execute(db) }
        try database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal", "Family", "Business"])
    }

    @Test func `the home counts open reminders only and lists the tags in use`() throws {
        let (database, sample) = try makeDatabase()
        let overview = try overview(database)
        #expect(overview.counts == Reminders.Summary.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        #expect(overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(overview.lists.map(\.count) == [4, 2, 2])
        #expect(Set(overview.tags.filter { $0.count > 0 }.map(\.tag.rawValue)) == ["adulting", "car", "kids", "night", "optional", "social", "someday"])
        #expect(overview.tags.prefix(3).map(\.tag.rawValue) == ["social", "adulting", "optional"])
        try database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        #expect(try self.overview(database).lists.map(\.count) == [3, 2, 2])
    }

    @Test func `a detail and a search read their first rows with the count of all of them`() throws {
        let (database, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        let window = try detail(personal, database, limit: 2)
        #expect(window.reminders.map(\.title) == ["Haircut", "Doctor appointment"])
        #expect(window.total == 4 && window.rows.count < window.total)
        #expect(window.completed == 1)
        let whole = try detail(personal, database)
        #expect(whole.rows.count == 4 && whole.total == 4)
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .dueDate, showCompleted: true), for: personal).execute(db) }
        let shown = try detail(personal, database, limit: 1)
        #expect(shown.rows.count == 1 && shown.total == 5 && shown.completed == 1)
        let matches = try results(Reminders.Query(terms: ["Take"], showCompleted: true), database, limit: 1)
        #expect(matches.reminders.map(\.title) == ["Take a walk"] && matches.total == 2 && matches.rows.count < matches.total)
        #expect(matches.completed == 1 && matches.rows.count == 1)
        #expect(try results(Reminders.Query(terms: ["Take"], showCompleted: true), database).total == 2)
    }

    @Test func `a detail filters by membership and orders by its preference`() throws {
        let (database, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        var detail = try detail(personal, database)
        #expect(detail.reminders.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .priority, showCompleted: false), for: personal).execute(db) }
        detail = try self.detail(personal, database)
        #expect(try preference(personal, database).ordering == .priority)
        #expect(detail.reminders.map(\.title) == ["Doctor appointment", "Haircut", "Groceries", "Buy concert tickets"])
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .title, showCompleted: false), for: personal).execute(db) }
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Buy concert tickets", "Doctor appointment", "Groceries", "Haircut"])
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .creationDate, showCompleted: false), for: personal).execute(db) }
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Groceries", "Haircut", "Doctor appointment", "Buy concert tickets"])
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .creationDate, showCompleted: true), for: personal).execute(db) }
        detail = try self.detail(personal, database)
        #expect(try preference(personal, database).showCompleted && detail.reminders.map(\.title).last == "Take a walk")
        #expect(try self.detail(.completed, database).reminders.count == 3)
        #expect(try self.detail(.today, database).reminders.count == 2)
        #expect(try self.detail(.scheduled, database).reminders.count == 7)
        #expect(try self.detail(.flagged, database).reminders.map(\.title) == ["Haircut", "Pick up kids from school"])
        #expect(try self.detail(.tags(["social"]), database).reminders.map(\.title) == ["Buy concert tickets", "Prepare for WWDC"])
        #expect(try self.detail(.all, database).reminders.count == 8)
        #expect(try self.detail(.all, database).rows.map(\.list).contains(sample.lists[2].id))
        #expect(try self.detail(personal, database).reminders.first { $0.title == "Groceries" }?.tags == ["someday", "optional", "adulting"])
    }

    @Test func `titles order case-insensitively and the row being edited keeps its place`() throws {
        let (database, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        let groceries = sample.reminders[0]
        try database.write { db in
            try Reminder.Record.save({ var draft = Reminder.Record.Draft(groceries); draft.title = "apples"; return draft }()).execute(db)
            try Reminders.Preference.Record.set(Reminders.Preference(ordering: .title, showCompleted: false), for: personal).execute(db)
        }
        #expect(try detail(personal, database).reminders.map(\.title) == ["apples", "Buy concert tickets", "Doctor appointment", "Haircut"])
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .dueDate, showCompleted: false), for: personal).execute(db) }
        var dated = Reminder.Record.Draft(groceries)
        dated.title = "apples"
        dated.due = .day(now.addingTimeInterval(-400_000))
        try database.write { db in try Reminder.Record.save(dated).execute(db) }
        #expect(try detail(personal, database).reminders.first?.id == groceries.id)
        #expect(try detail(personal, database, including: Reminders.Placement(groceries, position: 0)).reminders.last?.id == groceries.id)
    }

    @Test func `a toggle flips completion and a toggle of a missing row is nothing`() throws {
        let (database, sample) = try makeDatabase()
        let groceries = sample.reminders[0].id
        try database.write { db in try Reminder.Record.toggle(groceries).execute(db) }
        #expect(try stored(groceries, database)?.completed == true)
        #expect(try overview(database).counts.all == 7)
        try database.write { db in
            try Reminder.Record.toggle(groceries).execute(db)
            try Reminder.Record.toggle(Reminder.ID(UUID())).execute(db)
        }
        #expect(try stored(groceries, database)?.completed == false)
        #expect(try overview(database).counts.all == 8)
    }

    @Test func `deleting a list takes its reminders and the last one is replaced by the default`() throws {
        let (database, sample) = try makeDatabase()
        let business = sample.lists[2].id
        try database.write { db in try Models.List<Reminder>.Record.delete(business, replacement: Models.List<Reminder>.ID(UUID()), in: db) }
        #expect(try database.read { db in try Reminder.Record.where { $0.listID.eq(business) }.fetchCount(db) } == 0)
        #expect(try database.read { db in try Reminders.Tagging.all.fetchCount(db) } == sample.reminders.filter { $0.list != business }.reduce(0) { $0 + $1.tags.count })
        let replacement = Models.List<Reminder>.ID(UUID())
        try database.write { db in
            try Models.List<Reminder>.Record.delete(sample.lists[0].id, replacement: Models.List<Reminder>.ID(UUID()), in: db)
            try Models.List<Reminder>.Record.delete(sample.lists[1].id, replacement: replacement, in: db)
        }
        let overview = try overview(database)
        #expect(overview.lists.map(\.list.title) == ["Personal"] && overview.lists.first?.id == replacement && overview.counts.all == 0)
    }

    @Test func `a new list takes the last position and lists move as SwiftUI moves them`() throws {
        let (database, sample) = try makeDatabase()
        let chores = Models.List<Reminder>(id: Models.List<Reminder>.ID(UUID()), title: "Chores")
        try database.write { db in
            try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(chores) }.execute(db)
            try Models.List<Reminder>.Record.placeLast(chores.id).execute(db)
        }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal", "Family", "Business", "Chores"])
        let before = try overview(database).lists.map(\.id)
        let ids = [before[1], before[2], before[0], before[3]]
        try database.write { db in try Models.List<Reminder>.Record.reorder(ids).execute(db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Family", "Business", "Personal", "Chores"])
        var renamed = sample.lists[1]
        renamed.title = "Home"
        try database.write { db in try Models.List<Reminder>.Record.save(Models.List<Reminder>.Record.Draft(Models.List<Reminder>.Record(renamed))).execute(db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Home", "Business", "Personal", "Chores"])
        #expect(try database.read { db in try Models.List<Reminder>.Record.order(by: \.position).select(\.position).fetchAll(db) } == [0, 1, 2, 3])
    }

    @Test func `tags are shared, renamed everywhere, merged when renamed onto another, and deleted everywhere`() throws {
        let (database, sample) = try makeDatabase()
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("social", to: "friends", in: db) } == "friends")
        #expect(try detail(.tags(["friends"]), database).reminders.count == 2)
        #expect(try stored(sample.reminders[3].id, database)?.tags == ["car", "kids", "friends"])
        try database.write { db in try Tag<Reminder>.Record.delete("friends").execute(db) }
        #expect(try database.read { db in try Reminders.Tagging.where { $0.tagID.eq(Tag<Reminder>("friends")) }.fetchCount(db) } == 0)
        #expect(try database.write { db in try Tag<Reminder>.Record.add("Someday", in: db) } == "someday")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["CAR"], created: now)
        try database.write { db in
            try Reminder.Record.insert { Reminder.Record.Draft(wash) }.execute(db)
            try Reminder.Record.placeLast(wash.id).execute(db)
            try Reminders.Tagging.attach(wash.tags, to: wash.id, in: db)
        }
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        #expect(try stored(wash.id, database)?.tags == ["car"])
        #expect(try position(wash.id, database) == 11)
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("car", to: "Car", in: db) } == "Car")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Car"))
        #expect(try stored(wash.id, database)?.tags == ["Car"])
        #expect(try detail(.tags(["Car"]), database).reminders.map(\.title) == ["Wash"])
        #expect(Set(try overview(database).tags.filter { $0.count > 0 }.map(\.tag.rawValue)) == ["adulting", "Car", "kids", "night", "optional", "someday"])
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
        #expect(try overview(database).tags.map(\.tag.rawValue) == ["social", "adulting", "optional", "someday", "Car", "kids", "night", "Cat"])
        #expect(try suggestions("c", database).map(\.rawValue) == ["Car", "Cat"])
        #expect(try suggestions("so", database).map(\.rawValue) == ["social", "someday"])
        #expect(try suggestions("so", excluding: ["social"], database).map(\.rawValue) == ["someday"])
        #expect(try suggestions("", database).isEmpty)
    }

    @Test func `search matches text and tag tokens and can clear completed matches`() throws {
        let (database, sample) = try makeDatabase()
        #expect(try results(Reminders.Query(terms: ["Take"], showCompleted: true), database).reminders.map(\.title) == ["Take a walk", "Take out trash"])
        let hidden = try results(Reminders.Query(terms: ["Take"]), database)
        #expect(hidden.reminders.map(\.title) == ["Take out trash"] && hidden.completed == 1)
        #expect(hidden.rows.map(\.list) == [sample.lists[1].id])
        #expect(try results(Reminders.Query(terms: ["Take"], tags: ["car"], showCompleted: true), database).reminders.map(\.title) == ["Take a walk"])
        #expect(try results(Reminders.Query(terms: ["Take", "walk"], showCompleted: true), database).reminders.map(\.title) == ["Take a walk"])
        #expect(try results(Reminders.Query(terms: ["oatmeal"]), database).reminders.map(\.title) == ["Groceries"])
        #expect(try results(Reminders.Query(terms: ["ADULT"]), database).reminders.map(\.title) == ["Doctor appointment", "Groceries"])
        #expect(try results(Reminders.Query(terms: ["payroll"]), database).reminders.map(\.title) == ["Call accountant"])
        #expect(try results(Reminders.Query(tags: ["nothing"]), database).reminders.isEmpty)
        try database.write { [today] db in
            try Reminder.Record.toggle(sample.reminders[7].id).execute(db)
            try Reminder.Record.deleteCompleted(matching: Reminders.Query(terms: ["Take"]), dueBefore: calendar.date(byAdding: .month, value: -12, to: now)).execute(db)
        }
        #expect(try overview(database).counts.all == 7)
        #expect(try count(database) == 11)
        try database.write { [today] db in
            try Reminder.Record.deleteCompleted(matching: Reminders.Query(terms: ["Take"]), dueBefore: calendar.date(byAdding: .month, value: -1, to: now)).execute(db)
        }
        #expect(try count(database) == 10)
        #expect(try stored(sample.reminders[7].id, database)?.completed == true)
        #expect(try detail(.completed, database).reminders.map(\.title) == ["Get laundry", "Send weekly emails", "Take out trash"])
        try database.write { [today] db in try Reminder.Record.deleteCompleted(matching: Reminders.Query(tags: ["nothing"]), dueBefore: nil).execute(db) }
        #expect(try count(database) == 10)
        try database.write { [today] db in try Reminder.Record.deleteCompleted(in: .completed, today: today).execute(db) }
        #expect(try count(database) == 7)
        #expect(try detail(.completed, database).reminders.isEmpty)
    }

    @Test func `a save writes the form's columns last, replaces the tags, and leaves completion and position to the timer and the order`() throws {
        let (database, sample) = try makeDatabase()
        let groceries = sample.reminders[0]
        try database.write { db in
            try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db)
            try Reminder.Record.toggle(groceries.id).execute(db)
        }
        var draft = Reminder.Record.Draft(groceries)
        draft.title = "Groceries and more"
        draft.position = 99
        var tags = groceries.tags
        tags.insert("fresh")
        tags.remove("optional")
        #expect(try database.write { db in try Reminder.Record.save(draft, tags: tags, isNew: false, in: db) } == groceries.id)
        let stored = try stored(groceries.id, database)
        #expect(stored?.title == "Groceries and more" && stored?.flagged == false && stored?.tags == ["someday", "adulting", "fresh"])
        #expect(try stored?.completed == true && position(groceries.id, database) == 0)
        #expect(try self.stored(sample.reminders[1].id, database) == sample.reminders[1])
        var bread = Reminder.Record.Draft.start(in: groceries.list, created: now)
        bread.title = "Bread"
        let id = try #require(try database.write { db in try Reminder.Record.save(bread, tags: ["CAR"], isNew: true, in: db) })
        #expect(try self.stored(id, database)?.tags == ["car"] && position(id, database) == 11)
        try database.write { db in try Reminder.Record.find(id).delete().execute(db) }
        var back = bread
        back.id = id
        #expect(try database.write { db in try Reminder.Record.save(back, tags: [], isNew: false, in: db) } == nil)
        #expect(try self.stored(id, database) == nil)
    }

    @Test func `a row continues beneath its anchor and moves keep the positions they were given`() throws {
        let (database, sample) = try makeDatabase()
        let haircut = sample.reminders[1]
        let next = Reminder(id: Reminder.ID(UUID()), list: haircut.list, created: now)
        try database.write { db in
            try Reminder.Record.makeRoom(after: 1).execute(db)
            try Reminder.Record.insert { Reminder.Record.Draft(next, position: 2) }.execute(db)
        }
        #expect(try position(sample.reminders[2].id, database) == 3)
        let personal = Reminders.Filter.list(sample.lists[0].id)
        try database.write { db in try Reminders.Preference.Record.set(Reminders.Preference(ordering: .manual, showCompleted: false), for: personal).execute(db) }
        #expect(try detail(personal, database, including: { var p = haircut; p.id = next.id; return Reminders.Placement(p, position: 2) }()).reminders.map(\.id).prefix(3) == [sample.reminders[0].id, haircut.id, next.id])
        var ids = try detail(personal, database).reminders.map(\.id)
        ids.swapAt(0, 2)
        try database.write { db in try Reminder.Record.reorder(ids, in: db) }
        #expect(try detail(personal, database).reminders.map(\.id) == ids)
        #expect(try position(next.id, database) == 0)
    }

    @Test func `a preference for an unknown detail is ignored and each setter touches its own column`() throws {
        let (database, sample) = try makeDatabase()
        try database.write { db in
            try Reminders.Preference.Record.insert { Reminders.Preference.Record(key: Reminders.Filter.Key(rawValue: "nothing"), ordering: .title) }.execute(db)
        }
        #expect(try preference(.list(sample.lists[0].id), database) == Reminders.Preference(Reminders.Preference.Record.default(for: .list(sample.lists[0].id))))
        #expect(try preference(.completed, database) == Reminders.Preference(Reminders.Preference.Record.default(for: .completed)))
        try database.write { db in try Reminders.Preference.Record.set(showCompleted: false, for: .completed).execute(db) }
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .dueDate, showCompleted: false))
        try database.write { db in try Reminders.Preference.Record.set(ordering: .title, for: .completed).execute(db) }
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .title, showCompleted: false))
        try database.write { db in try Reminders.Preference.Record.set(showCompleted: true, for: .completed).execute(db) }
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .title, showCompleted: true))
    }

    @Test func `a tag is one tag in any case, including beyond ASCII, and links follow a rename`() throws {
        let (database, sample) = try makeDatabase()
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["Café"], created: now)
        try database.write { db in
            try Reminder.Record.insert { Reminder.Record.Draft(wash) }.execute(db)
            try Reminders.Tagging.attach(wash.tags, to: wash.id, in: db)
        }
        #expect(try database.write { db in try Tag<Reminder>.Record.add("CAFÉ", in: db) } == "Café")
        #expect(try database.write { db in try Tag<Reminder>.Record.add("café", in: db) } == "Café")
        try database.write { db in try Reminders.Tagging.attach(["CAFÉ"], to: sample.reminders[0].id, in: db) }
        #expect(try stored(sample.reminders[0].id, database)?.tags.contains("Café") == true)
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.filter { $0.lowercased() == "café" } == ["Café"])
        #expect(try detail(.tags(["Café"]), database).reminders.count == 2)
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("Café", to: "CAFÉ", in: db) } == "CAFÉ")
        #expect(try stored(wash.id, database)?.tags == ["CAFÉ"])
        #expect(try detail(.tags(["CAFÉ"]), database).reminders.count == 2)
        _ = try database.write { db in try Tag<Reminder>.Record.add("Straße", in: db) }
        #expect(try database.write { db in try Tag<Reminder>.Record.rename("Straße", to: "café", in: db) } == "CAFÉ")
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Straße") == false)
    }

    @Test func `upgrading a database keeps its records and folds tags that were twins under ASCII rules`() throws {
        var configuration = Configuration()
        Reminders.Schema.prepare(&configuration)
        let database = try DatabaseQueue(configuration: configuration)
        try Reminders.Schema.migrate(database, upTo: "Create the Reminders tables")
        let list = Models.List<Reminder>.ID(UUID())
        let (first, second) = (Reminder.ID(UUID()), Reminder.ID(UUID()))
        try database.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(first), \(list), 'Bread')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(second), \(list), 'Milk')").execute(db)
            try #sql("INSERT INTO tags (title) VALUES ('Café'), ('CAFÉ'), ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(first), 'Café'), (\(first), 'CAFÉ'), (\(second), 'CAFÉ'), (\(second), 'car')").execute(db)
        }
        try Reminders.Schema.migrate(database)
        let titles = try database.read { db in try Tag<Reminder>.Record.all.order(by: \.title).fetchAll(db).map(\.title) }
        #expect(titles == ["Café", "car"])
        #expect(try stored(first, database)?.tags == ["Café"])
        #expect(try stored(second, database)?.tags == ["Café", "car"])
        #expect(try stored(first, database)?.title == "Bread")
        #expect(try stored(first, database)?.created == Date(timeIntervalSince1970: 0))
        #expect(try database.read { db in try Reminders.Tagging.all.fetchCount(db) } == 3)
        try database.write { db in try Tag<Reminder>.Record.delete("café").execute(db) }
        #expect(try database.read { db in try Reminders.Tagging.all.fetchCount(db) } == 1)
        try Reminders.Schema.migrate(database)
    }

    @Test func `an upgraded database keeps its rows and lets the database mint ids`() throws {
        var configuration = Configuration()
        Reminders.Schema.prepare(&configuration)
        let database = try DatabaseQueue(configuration: configuration)
        try Reminders.Schema.migrate(database, upTo: "Keep the folded text for the search")
        let list = Models.List<Reminder>.ID(UUID())
        let bread = Reminder.ID(UUID())
        try database.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(bread), \(list), 'Bread')").execute(db)
            try #sql("INSERT INTO tags (title) VALUES ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(bread), 'car')").execute(db)
        }
        try Reminders.Schema.migrate(database)
        #expect(try stored(bread, database)?.title == "Bread" && stored(bread, database)?.tags == ["car"])
        try database.write { db in try #sql("INSERT INTO reminders (listID, title) VALUES (\(list), 'Milk')").execute(db) }
        try database.write { db in try #sql("INSERT INTO lists (title) VALUES ('Errands')").execute(db) }
        let milk = try #require(try database.read { db in try Reminder.Record.where { $0.title.eq("Milk") }.fetchOne(db) })
        #expect(milk.id.rawValue.uuidString.count == 36 && milk.listID == list)
        let errands = try #require(try database.read { db in try Models.List<Reminder>.Record.where { $0.title.eq("Errands") }.fetchOne(db) })
        #expect(errands.id.rawValue.uuidString.count == 36)
        var eggs = Reminder.Record.Draft.start(in: list, created: now)
        eggs.title = "Eggs"
        let id = try database.write { db in try Reminder.Record.append(eggs, in: db) }
        #expect(try stored(id, database)?.title == "Eggs" && position(id, database) == 1)
        #expect(try database.read { db in try #sql("SELECT searchText FROM reminders WHERE title = 'Milk'", as: String.self).fetchOne(db) } == "milk\n")
        try database.write { db in try Models.List<Reminder>.Record.find(list).delete().execute(db) }
        #expect(try database.read { db in try Reminder.Record.all.fetchCount(db) } == 0)
    }

    @Test func `a generated sample at scale is written in one transaction and read back whole`() throws {
        let database = try Reminders.Schema.database()
        let sample = Reminders.Sample.generated(.medium, seed: 1, at: now, calendar: calendar)
        try database.write { db in try sample.replace(in: db) }
        #expect(try database.read { db in try Reminder.Record.all.fetchCount(db) } == 1_000)
        #expect(try database.read { db in try Models.List<Reminder>.Record.all.fetchCount(db) } == 10)
        #expect(try database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 30)
        let links = sample.reminders.reduce(0) { $0 + $1.tags.count }
        #expect(try database.read { db in try Reminders.Tagging.all.fetchCount(db) } == links)
        let first = try #require(sample.reminders.first)
        #expect(try stored(first.id, database) == first)
        #expect(try overview(database).lists.count == 10)
        #expect(try overview(database).counts.all == sample.reminders.count { !$0.completed })
        try database.write { db in try Reminders.sample(at: now).replace(in: db) }
        #expect(try database.read { db in try Reminder.Record.all.fetchCount(db) } == 11)
    }

    @Test func `today is decided by the calendar's day, not the process time zone`() throws {
        let (database, sample) = try makeDatabase()
        let utc = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        let due = utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1))!
        let late = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Late", due: .day(due), created: now)
        try database.write { db in
            try Reminder.Record.delete().execute(db)
            try Reminder.Record.insert { Reminder.Record.Draft(late) }.execute(db)
        }
        func today(_ calendar: Calendar) throws -> [String] {
            try database.read { db in
                try Reminders.Page.Query(.filter(.today), today: calendar.day(containing: now)!, including: nil, limit: nil).fetch(db).reminders.map(\.title)
            }
        }
        func count(_ calendar: Calendar) throws -> Int {
            try database.read { db in try Reminders.Summary.Query(today: calendar.day(containing: now)!).fetch(db).counts.today }
        }
        #expect(try today(utc) == [] && count(utc) == 0)
        #expect(try today(tokyo) == ["Late"] && count(tokyo) == 1)
        let tomorrow = utc.day(containing: now.addingTimeInterval(.hour))!
        #expect(try database.read { db in try Reminders.Summary.Query(today: tomorrow).fetch(db).counts.today } == 1)
    }

    @Test func `a row that could not be read is refused by the schema, and one stored before the rule is brought back inside it`() throws {
        let (database, sample) = try makeDatabase()
        #expect(throws: (any Error).self) {
            try database.write { db in try #sql("UPDATE reminders SET due = 'garbage' WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        #expect(throws: (any Error).self) {
            try database.write { db in try #sql("UPDATE reminders SET completed = 7 WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        #expect(try detail(.all, database).reminders.count == 8)
        var configuration = Configuration()
        Reminders.Schema.prepare(&configuration)
        let old = try DatabaseQueue(configuration: configuration)
        try Reminders.Schema.migrate(old, upTo: "Compare tag titles as Swift does")
        let list = Models.List<Reminder>.ID(UUID())
        let (bad, good) = (Reminder.ID(UUID()), Reminder.ID(UUID()))
        try old.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title, due, status, priority) VALUES (\(bad), \(list), 'Bad', 'garbage', 9, 4)").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title, due, status, priority) VALUES (\(good), \(list), 'Good', '2026-09-15 10:00:00.000', 2, 3)").execute(db)
            try #sql("INSERT INTO tags (title) VALUES ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(bad), 'car')").execute(db)
        }
        try Reminders.Schema.migrate(old)
        let repaired = try old.read { db in try Reminder.Record.find(bad).rows().fetchOne(db).map(Reminder.init) }
        #expect(repaired?.due == nil && repaired?.completed == false && repaired?.priority == nil && repaired?.tags == ["car"])
        let kept = try old.read { db in try Reminder.Record.find(good).rows().fetchOne(db).map(Reminder.init) }
        #expect(kept?.completed == true && kept?.priority == .high && kept?.due != nil)
        #expect(try old.read { db in try #sql("SELECT completed FROM reminders WHERE id = \(good)", as: Int.self).fetchOne(db) } == 1)
        try old.write { db in try Models.List<Reminder>.Record.find(list).delete().execute(db) }
        #expect(try old.read { db in try Reminders.Tagging.all.fetchCount(db) } == 0)
    }

    func plan(_ statement: some Statement, _ database: some DatabaseWriter) throws -> [String] {
        try database.read { db in try #sql("EXPLAIN QUERY PLAN \(statement.query)", as: PlanStep.self).fetchAll(db).map(\.detail) }
    }

    @Selection struct PlanStep {
        let id: Int
        let parent: Int
        let notused: Int
        let detail: String
    }

    @Test func `a row's tag list is read through the tags index, not a scan of the tags per row`() throws {
        let (database, sample) = try makeDatabase()
        let steps = try plan(Reminder.Record.all.rows(), database)
        #expect(!steps.contains { $0.hasPrefix("SCAN tags") }, "\(steps)")
        #expect(steps.contains { $0.hasPrefix("SEARCH tags USING COVERING INDEX") }, "\(steps)")
        try database.write { db in _ = try Tag<Reminder>.Record.rename("someday", to: "Someday", in: db) }
        #expect(try stored(sample.reminders[0].id, database)?.tags == ["Someday", "optional", "adulting"])
    }

    @Test func `a search matches the tags once and looks each reminder's links up in their index`() throws {
        let (database, _) = try makeDatabase()
        let steps = try plan(Reminder.Record.where { $0.matches(Reminders.Query(terms: ["day"])) }.select(\.id), database)
        #expect(steps.contains { $0.contains("LIST SUBQUERY") }, "\(steps)")
        #expect(steps.contains { $0.hasPrefix("SCAN tags") }, "\(steps)")
        #expect(!steps.contains { $0.contains("CORRELATED") && $0.contains("tags") }, "\(steps)")
        #expect(try results(Reminders.Query(terms: ["SOMEDAY"], showCompleted: true), database).reminders.map(\.title) == ["Haircut", "Groceries"])
        let sql = "\(Reminder.Record.where { $0.matches(Reminders.Query(terms: ["day"])) }.select(\.id).query)"
        #expect(sql.contains("instr(\"reminders\".\"searchText\"") && !sql.contains("localizedCaseInsensitiveContains(\"reminders\""), "\(sql)")
        let groceries = try #require(try results(Reminders.Query(terms: ["oatmeal"], showCompleted: true), database).reminders.first)
        try database.write { db in try Reminder.Record.find(groceries.id).update { $0.title = "Weekly Shopping" }.execute(db) }
        #expect(try results(Reminders.Query(terms: ["shopping"], showCompleted: true), database).reminders.map(\.title) == ["Weekly Shopping"])
        #expect(try results(Reminders.Query(terms: ["grocer"], showCompleted: true), database).reminders.isEmpty)
        #expect(try results(Reminders.Query(terms: ["OATMEAL"], showCompleted: true), database).reminders.map(\.title) == ["Weekly Shopping"])
    }

    @Test func `Today and the completed set are read through indexes, not a scan of every reminder`() throws {
        let (database, _) = try makeDatabase()
        let today = try plan(Reminder.Record.where { $0.isDue(during: self.today) }.rows(), database)
        #expect(today.contains { $0.contains("idx_reminders_due") }, "\(today)")
        let completed = try plan(Reminder.Record.where { $0.isCompleted }.select(\.id), database)
        #expect(completed.contains { $0.contains("idx_reminders_completed") }, "\(completed)")
        #expect(try overview(database).counts.today == 2)
        #expect(try detail(.today, database).rows.map(\.title) == ["Doctor appointment", "Buy concert tickets"])
    }
}

extension Reminders.Page {
    var reminders: [Reminder] { rows }
}
