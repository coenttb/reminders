import Dependencies
import DependenciesTestSupport
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

@Suite(.dependencies {
    $0.calendar = Calendar(identifier: .gregorian)
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
})
struct `Reminder SQLite storage` {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    var today: Range<Date> { calendar.day(containing: now)! }

    func makeDatabase() throws -> (database: any DatabaseWriter, reminders: Reminders, sample: Reminders.Sample) {
        let database = try Reminders.Schema.database()
        let sample = Reminders.sample(at: now)
        try database.write { db in try sample.replace(in: db) }
        return (database, .sqlite(database), sample)
    }

    func overview(_ database: some DatabaseWriter) throws -> Reminders.Summary {
        try Reminders.sqlite(database).read(today: now)
    }

    func detail(_ filter: Reminders.Filter, _ database: some DatabaseWriter, including: Reminders.Placement? = nil, limit: Int? = nil) throws -> Reminders.Page {
        try Reminders.sqlite(database).read(page: filter, today: now, including: including, limit: limit)
    }

    func preference(_ filter: Reminders.Filter, _ database: some DatabaseWriter) throws -> Reminders.Preference {
        try Reminders.sqlite(database).read.preference(for: filter)
    }

    func results(_ query: Reminders.Query, _ database: some DatabaseWriter, limit: Int? = nil) throws -> Reminders.Page {
        try Reminders.sqlite(database).read(search: query, today: now, limit: limit)
    }

    func suggestions(_ prefix: String, excluding: Set<Models.Tag<Reminder>> = [], _ database: some DatabaseWriter) throws -> [Models.Tag<Reminder>] {
        try Reminders.sqlite(database).tags.suggest(prefix: prefix, excluding: excluding)
    }

    func stored(_ id: Reminder.ID, _ database: some DatabaseWriter) throws -> Reminder? {
        try database.read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init) }
    }

    func position(_ id: Reminder.ID, _ database: some DatabaseWriter) throws -> Int? {
        try database.read { db in try Reminder.Record.find(id).select(\.position).fetchOne(db) }
    }

    // The rows a screen can still reach; a deleted row stays in Recently Deleted for thirty days.
    func count(_ database: some DatabaseWriter) throws -> Int {
        try database.read { db in try Reminder.Record.where { $0.isKept }.fetchCount(db) }
    }

    @Test func `an empty database is installed with one list, and installing again changes nothing`() async throws {
        let database = try Reminders.Schema.database()
        #expect(try await database.read { db in try db.tableExists("session") } == false)
        let personal = Models.List<Reminder>.ID(UUID())
        try await database.write { db in try Models.List<Reminder>.Record.installDefault(personal, in: db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal"] && overview(database).lists.first?.id == personal)
        try await database.write { db in try Models.List<Reminder>.Record.installDefault(Models.List<Reminder>.ID(UUID()), in: db) }
        #expect(try overview(database).lists.map(\.id) == [personal])
        try await database.write { db in try Reminders.sample(at: now).initialize(in: db) }
        #expect(try overview(database).lists.map(\.id) == [personal])
    }

    @Test func `the sample is written into an empty database once, a later run leaves the database alone, and a reset replaces everything`() async throws {
        let database = try Reminders.Schema.database()
        let sample = Reminders.sample(at: now)
        try await database.write { db in
            try sample.initialize(in: db)
            try sample.initialize(in: db)
        }
        #expect(try overview(database).counts == Reminders.Summary.Counts(all: 8, flagged: 2, scheduled: 7, today: 3))
        try await database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        try await database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).counts.all == 7)
        try await database.write { db in try sample.replace(in: db) }
        #expect(try overview(database).counts.all == 8)
        #expect(try await database.read { db in try Reminders.Tagging.all.fetchCount(db) } == sample.reminders.reduce(0) { $0 + $1.tags.count })
        try await database.write { db in try Models.List<Reminder>.Record.delete().execute(db) }
        try await database.write { db in try sample.initialize(in: db) }
        #expect(try overview(database).lists.map(\.list.title) == ["Personal", "Family", "Business"])
    }

    @Test func `the home counts open reminders only and lists the tags in use`() async throws {
        let (database, _, sample) = try makeDatabase()
        let overview = try overview(database)
        #expect(overview.counts == Reminders.Summary.Counts(all: 8, flagged: 2, scheduled: 7, today: 3))
        #expect(overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(overview.lists.map(\.count) == [4, 2, 2])
        #expect(Set(overview.tags.filter { $0.count > 0 }.map(\.tag.rawValue)) == ["adulting", "car", "kids", "night", "optional", "social", "someday"])
        #expect(overview.tags.prefix(3).map(\.tag.rawValue) == ["social", "adulting", "optional"])
        try await database.write { db in try Reminder.Record.find(sample.reminders[0].id).delete().execute(db) }
        #expect(try self.overview(database).lists.map(\.count) == [3, 2, 2])
    }

    @Test func `a detail and a search read their first rows with the count of all of them`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        let window = try detail(personal, database, limit: 2)
        #expect(window.reminders.map(\.title) == ["Haircut", "Doctor appointment"])
        #expect(window.total == 4 && window.rows.count < window.total)
        #expect(window.completed == 1)
        let whole = try detail(personal, database)
        #expect(whole.rows.count == 4 && whole.total == 4)
        try await reminders.update.order(personal, by: .dueDate)
        try await reminders.update.show(completed: true, in: personal)
        let shown = try detail(personal, database, limit: 1)
        #expect(shown.rows.count == 1 && shown.total == 5 && shown.completed == 1)
        let matches = try results(Reminders.Query(terms: ["Take"], showCompleted: true), database, limit: 1)
        #expect(matches.reminders.map(\.title) == ["Take a walk"] && matches.total == 2 && matches.rows.count < matches.total)
        #expect(matches.completed == 1 && matches.rows.count == 1)
        #expect(try results(Reminders.Query(terms: ["Take"], showCompleted: true), database).total == 2)
    }

    @Test func `a detail filters by membership and orders by its preference`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        var detail = try detail(personal, database)
        #expect(detail.reminders.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        try await reminders.update.order(personal, by: .priority)
        try await reminders.update.show(completed: false, in: personal)
        detail = try self.detail(personal, database)
        #expect(try preference(personal, database).ordering == .priority)
        #expect(detail.reminders.map(\.title) == ["Doctor appointment", "Haircut", "Groceries", "Buy concert tickets"])
        try await reminders.update.order(personal, by: .title)
        try await reminders.update.show(completed: false, in: personal)
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Buy concert tickets", "Doctor appointment", "Groceries", "Haircut"])
        try await reminders.update.order(personal, by: .creationDate)
        try await reminders.update.show(completed: false, in: personal)
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Groceries", "Haircut", "Doctor appointment", "Buy concert tickets"])
        try await reminders.update.turn(personal, .reverse)
        #expect(try preference(personal, database).direction == .reverse)
        #expect(try self.detail(personal, database).reminders.map(\.title) == ["Buy concert tickets", "Doctor appointment", "Haircut", "Groceries"])
        try await reminders.update.order(personal, by: .creationDate)
        #expect(try preference(personal, database).direction == .forward)
        try await reminders.update.order(personal, by: .creationDate)
        try await reminders.update.show(completed: true, in: personal)
        detail = try self.detail(personal, database)
        #expect(try preference(personal, database).showCompleted && detail.reminders.map(\.title).last == "Take a walk")
        #expect(try self.detail(.completed, database).reminders.count == 3)
        #expect(try self.detail(.today, database).reminders.count == 3)
        #expect(try self.detail(.scheduled, database).reminders.count == 7)
        #expect(try self.detail(.flagged, database).reminders.map(\.title) == ["Haircut", "Pick up kids from school"])
        #expect(try self.detail(.tags(["social"]), database).reminders.map(\.title) == ["Buy concert tickets", "Prepare for WWDC"])
        #expect(try self.detail(.all, database).reminders.count == 8)
        #expect(try self.detail(.all, database).rows.map(\.list).contains(sample.lists[2].id))
        // A smart list comes list by list, in the lists' order, each list by the smart list's own ordering.
        let lists = sample.lists.map(\.id)
        #expect(try self.detail(.all, database).rows.map(\.list) == [lists[0], lists[0], lists[0], lists[0], lists[1], lists[1], lists[2], lists[2]])
        #expect(try self.detail(.all, database).reminders.map(\.title).prefix(4) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        #expect(try self.detail(.flagged, database).rows.map(\.list) == [lists[0], lists[1]])
        #expect(Reminders.Filter.all.groupsByList && Reminders.Filter.tags(["social"]).groupsByList && !Reminders.Filter.scheduled.groupsByList && !Reminders.Filter.list(lists[0]).groupsByList)
        #expect(try self.detail(personal, database).reminders.first { $0.title == "Groceries" }?.tags == ["someday", "optional", "adulting"])
    }

    @Test func `a reversed direction turns the key around and keeps the rows without one last`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        try await reminders.update.order(personal, by: .dueDate)
        try await reminders.update.turn(personal, .reverse)
        // Doctor and the tickets are due at the same instant; the tie keeps the manual order in both directions.
        #expect(try detail(personal, database).reminders.map(\.title) == ["Doctor appointment", "Buy concert tickets", "Haircut", "Groceries"])
        try await reminders.update.order(personal, by: .priority)
        #expect(try detail(personal, database).reminders.map(\.title) == ["Doctor appointment", "Haircut", "Groceries", "Buy concert tickets"])
        try await reminders.update.turn(personal, .reverse)
        #expect(try detail(personal, database).reminders.map(\.title) == ["Doctor appointment", "Groceries", "Buy concert tickets", "Haircut"])
        try await reminders.update.order(personal, by: .title)
        try await reminders.update.turn(personal, .reverse)
        #expect(try detail(personal, database).reminders.map(\.title) == ["Haircut", "Groceries", "Doctor appointment", "Buy concert tickets"])
        try await reminders.update.order(personal, by: .manual)
        try await reminders.update.turn(personal, .reverse)
        #expect(try detail(personal, database).reminders.map(\.title) == ["Groceries", "Haircut", "Doctor appointment", "Buy concert tickets"])
        try await reminders.update.show(completed: true, in: personal)
        #expect(try detail(personal, database).reminders.map(\.title).last == "Take a walk")
    }

    @Test func `titles order case-insensitively and the row being edited keeps its place`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let personal = Reminders.Filter.list(sample.lists[0].id)
        let groceries = sample.reminders[0]
        var apples = groceries
        apples.title = "apples"
        _ = try await reminders.update(apples)
        try await reminders.update.order(personal, by: .title)
        #expect(try detail(personal, database).reminders.map(\.title) == ["apples", "Buy concert tickets", "Doctor appointment", "Haircut"])
        try await reminders.update.order(personal, by: .dueDate)
        try await reminders.update.show(completed: false, in: personal)
        apples.due = .day(now.addingTimeInterval(-400_000))
        _ = try await reminders.update(apples)
        #expect(try detail(personal, database).reminders.first?.id == groceries.id)
        #expect(try detail(personal, database, including: Reminders.Placement(groceries, position: 0)).reminders.last?.id == groceries.id)
    }

    @Test func `an update writes completion and an update of a missing row is refused`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        var groceries = sample.reminders[0]
        groceries.completed = now
        _ = try await reminders.update(groceries)
        #expect(try stored(groceries.id, database)?.isCompleted == true)
        #expect(try overview(database).counts.all == 7)
        groceries.completed = nil
        _ = try await reminders.update(groceries)
        await #expect(throws: Reminders.Update.Error.notFound) {
            try await reminders.update(Reminder(id: Reminder.ID(UUID()), list: groceries.list, created: now))
        }
        #expect(try stored(groceries.id, database)?.isCompleted == false)
        #expect(try overview(database).counts.all == 8)
    }

    @Test func `deleting a list takes its reminders and the last one is replaced by the default`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let business = sample.lists[2].id
        try await reminders.lists.delete(business, replacement: Models.List<Reminder>.ID(UUID()))
        #expect(try await database.read { db in try Reminder.Record.where { $0.listID.eq(business) }.fetchCount(db) } == 0)
        #expect(try await database.read { db in try Reminders.Tagging.all.fetchCount(db) } == sample.reminders.filter { $0.list != business }.reduce(0) { $0 + $1.tags.count })
        let replacement = Models.List<Reminder>.ID(UUID())
        try await reminders.lists.delete(sample.lists[0].id, replacement: Models.List<Reminder>.ID(UUID()))
        try await reminders.lists.delete(sample.lists[1].id, replacement: replacement)
        let overview = try overview(database)
        #expect(overview.lists.map(\.list.title) == ["Personal"] && overview.lists.first?.id == replacement && overview.counts.all == 0)
    }

    @Test func `a new list takes the last position and lists move as SwiftUI moves them`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let chores = Models.List<Reminder>(id: Models.List<Reminder>.ID(UUID()), title: "Chores")
        try await reminders.lists.create(chores)
        #expect(try overview(database).lists.map(\.list.title) == ["Personal", "Family", "Business", "Chores"])
        let before = try overview(database).lists.map(\.id)
        let ids = [before[1], before[2], before[0], before[3]]
        try await reminders.lists.reorder(ids)
        #expect(try overview(database).lists.map(\.list.title) == ["Family", "Business", "Personal", "Chores"])
        var renamed = sample.lists[1]
        renamed.title = "Home"
        try await reminders.lists.update(renamed)
        #expect(try overview(database).lists.map(\.list.title) == ["Home", "Business", "Personal", "Chores"])
        #expect(try await database.read { db in try Models.List<Reminder>.Record.order(by: \.position).select(\.position).fetchAll(db) } == [0, 1, 2, 3])
    }

    @Test func `tags are shared, renamed everywhere, merged when renamed onto another, and deleted everywhere`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        #expect(try await reminders.tags.rename("social", to: "friends") == "friends")
        #expect(try detail(.tags(["friends"]), database).reminders.count == 2)
        #expect(try stored(sample.reminders[3].id, database)?.tags == ["car", "kids", "friends"])
        try await reminders.tags.delete("friends")
        #expect(try await database.read { db in try Reminders.Tagging.where { $0.tagID.eq(Tag<Reminder>("friends")) }.fetchCount(db) } == 0)
        #expect(try await reminders.tags.create("Someday") == "someday")
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["CAR"], created: now)
        _ = try await reminders.create(wash, below: nil)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        #expect(try stored(wash.id, database)?.tags == ["car"])
        #expect(try position(wash.id, database) == 11)
        #expect(try await reminders.tags.rename("car", to: "Car") == "Car")
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Car"))
        #expect(try stored(wash.id, database)?.tags == ["Car"])
        #expect(try detail(.tags(["Car"]), database).reminders.map(\.title) == ["Wash"])
        #expect(Set(try overview(database).tags.filter { $0.count > 0 }.map(\.tag.rawValue)) == ["adulting", "Car", "kids", "night", "optional", "someday"])
        #expect(try await reminders.tags.rename("kids", to: "car") == "Car")
        #expect(try stored(sample.reminders[3].id, database)?.tags == ["Car"])
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 5)
        await #expect(throws: Reminders.Tags.Error.notFound) { try await reminders.tags.rename("nothing", to: "x") }
    }

    @Test func `tags rank by use and suggestions complete a prefix case-insensitively`() async throws {
        let (database, reminders, _) = try makeDatabase()
        _ = try await reminders.tags.rename("car", to: "Car")
        _ = try await reminders.tags.create("Cat")
        #expect(try overview(database).tags.map(\.tag.rawValue) == ["social", "adulting", "optional", "someday", "Car", "kids", "night", "Cat"])
        #expect(try suggestions("c", database).map(\.rawValue) == ["Car", "Cat"])
        #expect(try suggestions("so", database).map(\.rawValue) == ["social", "someday"])
        #expect(try suggestions("so", excluding: ["social"], database).map(\.rawValue) == ["someday"])
        #expect(try suggestions("", database).isEmpty)
    }

    @Test func `search matches text and tag tokens and can clear completed matches`() async throws {
        let (database, reminders, sample) = try makeDatabase()
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
        var trash = sample.reminders[7]
        trash.completed = now
        _ = try await reminders.update(trash)
        try await reminders.delete.completed(matching: Reminders.Query(terms: ["Take"]), dueBefore: calendar.date(byAdding: .month, value: -12, to: now))
        #expect(try overview(database).counts.all == 7)
        #expect(try count(database) == 11)
        try await reminders.delete.completed(matching: Reminders.Query(terms: ["Take"]), dueBefore: calendar.date(byAdding: .month, value: -1, to: now))
        #expect(try count(database) == 10)
        #expect(try stored(sample.reminders[7].id, database)?.isCompleted == true)
        // The Completed screen runs newest first: trash now, laundry a day ago, the emails two days ago.
        #expect(try detail(.completed, database).reminders.map(\.title) == ["Take out trash", "Get laundry", "Send weekly emails"])
        try await reminders.delete.completed(matching: Reminders.Query(tags: ["nothing"]), dueBefore: nil)
        #expect(try count(database) == 10)
        try await reminders.delete.completed(in: .completed, today: now)
        #expect(try count(database) == 7)
        #expect(try detail(.completed, database).reminders.isEmpty)
    }

    @Test func `an update writes the whole reminder, replaces the tags, and leaves the position to the order`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        var groceries = sample.reminders[0]
        let id = groceries.id
        try await database.write { db in
            try Reminder.Record.find(id).update { $0.flagged = true; $0.position = 99 }.execute(db)
        }
        groceries.title = "Groceries and more"
        groceries.completed = now
        groceries.tags.insert("fresh")
        groceries.tags.remove("optional")
        #expect(try await reminders.update(groceries).position == 99)
        let stored = try stored(groceries.id, database)
        #expect(stored?.title == "Groceries and more" && stored?.flagged == false && stored?.tags == ["someday", "adulting", "fresh"])
        #expect(try stored?.isCompleted == true && position(groceries.id, database) == 99)
        #expect(try self.stored(sample.reminders[1].id, database) == sample.reminders[1])
        let bread = Reminder(id: Reminder.ID(UUID()), list: groceries.list, title: "Bread", tags: ["CAR"], created: now)
        #expect(try await reminders.create(bread, below: nil).position == 100)
        #expect(try self.stored(bread.id, database)?.tags == ["car"] && position(bread.id, database) == 100)
        try await reminders.delete(bread.id)
        await #expect(throws: Reminders.Update.Error.notFound) { try await reminders.update(bread) }
        #expect(try self.stored(bread.id, database)?.isDeleted == true)
        try await reminders.update.recover(bread.id)
        #expect(try self.stored(bread.id, database)?.isDeleted == false)
        try await reminders.delete.permanently(bread.id)
        #expect(try self.stored(bread.id, database) == nil)
    }

    @Test func `a row continues beneath its anchor and moves keep the positions they were given`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let haircut = sample.reminders[1]
        let next = Reminder(id: Reminder.ID(UUID()), list: haircut.list, created: now)
        #expect(try await reminders.create(next, below: Reminders.Placement(haircut, position: 1)).position == 2)
        #expect(try position(sample.reminders[2].id, database) == 3)
        let personal = Reminders.Filter.list(sample.lists[0].id)
        try await reminders.update.order(personal, by: .manual)
        try await reminders.update.show(completed: false, in: personal)
        #expect(try detail(personal, database, including: { var p = haircut; p.id = next.id; return Reminders.Placement(p, position: 2) }()).reminders.map(\.id).prefix(3) == [sample.reminders[0].id, haircut.id, next.id])
        var ids = try detail(personal, database).reminders.map(\.id)
        ids.swapAt(0, 2)
        try await reminders.update.reorder(ids, in: personal)
        #expect(try detail(personal, database).reminders.map(\.id) == ids)
        #expect(try position(next.id, database) == 0)
    }

    @Test func `a preference for an unknown detail is ignored and each setter touches its own column`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        try await database.write { db in
            try Reminders.Preference.Record.insert { Reminders.Preference.Record(key: Reminders.Filter.Key(rawValue: "nothing"), ordering: .title) }.execute(db)
        }
        #expect(try preference(.list(sample.lists[0].id), database) == Reminders.Preference(ordering: .dueDate, showCompleted: false))
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .dueDate, showCompleted: true))
        try await reminders.update.show(completed: false, in: .completed)
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .dueDate, showCompleted: false))
        try await reminders.update.order(.completed, by: .title)
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .title, showCompleted: false))
        try await reminders.update.show(completed: true, in: .completed)
        #expect(try preference(.completed, database) == Reminders.Preference(ordering: .title, showCompleted: true))
    }

    @Test func `a tag is one tag in any case, including beyond ASCII, and links follow a rename`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let wash = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Wash", tags: ["Café"], created: now)
        _ = try await reminders.create(wash, below: nil)
        #expect(try await reminders.tags.create("CAFÉ") == "Café")
        #expect(try await reminders.tags.create("café") == "Café")
        var groceries = sample.reminders[0]
        groceries.tags.insert("CAFÉ")
        _ = try await reminders.update(groceries)
        #expect(try stored(sample.reminders[0].id, database)?.tags.contains("Café") == true)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.filter { $0.lowercased() == "café" } == ["Café"])
        #expect(try detail(.tags(["Café"]), database).reminders.count == 2)
        #expect(try await reminders.tags.rename("Café", to: "CAFÉ") == "CAFÉ")
        #expect(try stored(wash.id, database)?.tags == ["CAFÉ"])
        #expect(try detail(.tags(["CAFÉ"]), database).reminders.count == 2)
        _ = try await reminders.tags.create("Straße")
        #expect(try await reminders.tags.rename("Straße", to: "café") == "CAFÉ")
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("Straße") == false)
    }

    @Test func `the database mints ids, and rows written raw are indexed for the search`() async throws {
        let database = try Reminders.Schema.database()
        let list = Models.List<Reminder>.ID(UUID())
        let bread = Reminder.ID(UUID())
        try await database.write { db in
            try #sql("INSERT INTO lists (id, title) VALUES (\(list), 'Personal')").execute(db)
            try #sql("INSERT INTO reminders (id, listID, title) VALUES (\(bread), \(list), 'Bread')").execute(db)
            try #sql("INSERT INTO tags (title) VALUES ('car')").execute(db)
            try #sql("INSERT INTO remindersTags (reminderID, tagID) VALUES (\(bread), 'car')").execute(db)
        }
        #expect(try stored(bread, database)?.title == "Bread" && stored(bread, database)?.tags == ["car"])
        #expect(try stored(bread, database)?.created == Date(timeIntervalSince1970: 0))
        try await database.write { db in try #sql("INSERT INTO reminders (listID, title) VALUES (\(list), 'Milk')").execute(db) }
        try await database.write { db in try #sql("INSERT INTO lists (title) VALUES ('Errands')").execute(db) }
        let milk = try #require(try await database.read { db in try Reminder.Record.where { $0.title.eq("Milk") }.fetchOne(db) })
        #expect(milk.id.rawValue.uuidString.count == 36 && milk.listID == list)
        let errands = try #require(try await database.read { db in try Models.List<Reminder>.Record.where { $0.title.eq("Errands") }.fetchOne(db) })
        #expect(errands.id.rawValue.uuidString.count == 36)
        let eggs = Reminder(id: Reminder.ID(UUID()), list: list, title: "Eggs", created: now)
        #expect(try await Reminders.sqlite(database).create(eggs, below: nil).position == 1)
        #expect(try stored(eggs.id, database)?.title == "Eggs" && position(eggs.id, database) == 1)
        #expect(try results(Reminders.Query(terms: ["car"], showCompleted: true), database).reminders.map(\.title) == ["Bread"])
        #expect(try results(Reminders.Query(terms: ["mi"], showCompleted: true), database).reminders.map(\.title) == ["Milk"])
        try await database.write { db in try Models.List<Reminder>.Record.find(list).delete().execute(db) }
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 0)
        #expect(try await database.read { db in try Reminder.Record.Text.all.fetchCount(db) } == 0)
    }

    @Test func `a generated sample at scale is written in one transaction and read back whole`() async throws {
        let database = try Reminders.Schema.database()
        let sample = Reminders.Sample.generated(.medium, seed: 1, at: now, calendar: calendar)
        try await database.write { db in try sample.replace(in: db) }
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 1_000)
        #expect(try await database.read { db in try Models.List<Reminder>.Record.all.fetchCount(db) } == 10)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 30)
        let links = sample.reminders.reduce(0) { $0 + $1.tags.count }
        #expect(try await database.read { db in try Reminders.Tagging.all.fetchCount(db) } == links)
        let first = try #require(sample.reminders.first)
        #expect(try stored(first.id, database) == first)
        #expect(try overview(database).lists.count == 10)
        #expect(try overview(database).counts.all == sample.reminders.count { !$0.isCompleted })
        try await database.write { db in try Reminders.sample(at: now).replace(in: db) }
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 11)
    }

    @Test func `today is decided by the calendar's day, not the process time zone`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let utc = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        let due = utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1))!
        let late = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Late", due: .day(due), created: now)
        try await database.write { db in
            try Reminder.Record.delete().execute(db)
            try Reminder.Record.insert { Reminder.Record.Draft(late) }.execute(db)
        }
        func today(_ calendar: Calendar) throws -> [String] {
            try withDependencies { $0.calendar = calendar } operation: {
                try reminders.read(page: .today, today: now, including: nil, limit: nil).reminders.map(\.title)
            }
        }
        func count(_ calendar: Calendar, at date: Date) throws -> Int {
            try withDependencies { $0.calendar = calendar } operation: {
                try reminders.read(today: date).counts.today
            }
        }
        #expect(try today(utc) == [] && count(utc, at: now) == 0)
        #expect(try today(tokyo) == ["Late"] && count(tokyo, at: now) == 1)
        #expect(try count(utc, at: now.addingTimeInterval(.hour)) == 1)
    }

    @Test func `a row that could not be read is refused by the schema`() async throws {
        let (database, _, sample) = try makeDatabase()
        await #expect(throws: (any Error).self) {
            try await database.write { db in try #sql("UPDATE reminders SET due = 'garbage' WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        await #expect(throws: (any Error).self) {
            try await database.write { db in try #sql("UPDATE reminders SET completed = 7 WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        await #expect(throws: (any Error).self) {
            try await database.write { db in try #sql("UPDATE reminders SET priority = 4 WHERE id = \(sample.reminders[0].id)").execute(db) }
        }
        #expect(try detail(.all, database).reminders.count == 8)
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

    @Test func `a row's tag list is read through the tags index, not a scan of the tags per row`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let steps = try plan(Reminder.Record.all.rows(), database)
        #expect(!steps.contains { $0.hasPrefix("SCAN tags") }, "\(steps)")
        #expect(steps.contains { $0.hasPrefix("SEARCH tags USING COVERING INDEX") }, "\(steps)")
        _ = try await reminders.tags.rename("someday", to: "Someday")
        #expect(try stored(sample.reminders[0].id, database)?.tags == ["Someday", "optional", "adulting"])
    }

    @Test func `a search is answered by the full-text index, at the start of a word, in any case, and follows every edit`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let steps = try plan(Reminder.Record.where { $0.matches(Reminders.Query(terms: ["day"])) }.select(\.id), database)
        #expect(steps.contains { $0.contains("VIRTUAL TABLE INDEX") && $0.contains("reminderTexts") }, "\(steps)")
        #expect(!steps.contains { $0.contains("SCAN tags") || $0.contains("SCAN remindersTags") }, "\(steps)")
        #expect(try results(Reminders.Query(terms: ["SOMEDAY"], showCompleted: true), database).reminders.map(\.title) == ["Haircut", "Groceries"])
        #expect(try results(Reminders.Query(terms: ["some"], showCompleted: true), database).reminders.map(\.title) == ["Haircut", "Groceries"])
        #expect(try results(Reminders.Query(terms: ["meday"], showCompleted: true), database).reminders.isEmpty)
        #expect(try results(Reminders.Query(terms: ["take a"], showCompleted: true), database).reminders.map(\.title) == ["Take a walk"])
        #expect(try results(Reminders.Query(terms: ["\"take\" OR (x"], showCompleted: true), database).reminders.isEmpty)
        let groceries = try #require(try results(Reminders.Query(terms: ["oatmeal"], showCompleted: true), database).reminders.first)
        try await database.write { db in try Reminder.Record.find(groceries.id).update { $0.title = "Weekly Shopping" }.execute(db) }
        #expect(try results(Reminders.Query(terms: ["shopping"], showCompleted: true), database).reminders.map(\.title) == ["Weekly Shopping"])
        #expect(try results(Reminders.Query(terms: ["grocer"], showCompleted: true), database).reminders.isEmpty)
        #expect(try results(Reminders.Query(terms: ["OATMEAL"], showCompleted: true), database).reminders.map(\.title) == ["Weekly Shopping"])
        var shopping = groceries
        shopping.title = "Weekly Shopping"
        shopping.tags = ["café", "kids"]
        _ = try await reminders.update(shopping)
        #expect(try results(Reminders.Query(terms: ["cafe"], showCompleted: true), database).reminders.map(\.title) == ["Weekly Shopping"])
        #expect(try results(Reminders.Query(terms: ["adult"], showCompleted: true), database).reminders.map(\.title) == ["Doctor appointment"])
        _ = try await reminders.tags.rename("kids", to: "children")
        #expect(try results(Reminders.Query(terms: ["child"], showCompleted: true), database).reminders.count == 2)
        try await reminders.delete(groceries.id)
        #expect(try results(Reminders.Query(terms: ["shopping"], showCompleted: true), database).reminders.isEmpty)
        try await reminders.delete.permanently(groceries.id)
        #expect(try await database.read { db in try Reminder.Record.Text.all.fetchCount(db) } == 10)
    }

    @Test func `a search marks what matched and ranks a title above a note within a list`() async throws {
        let (database, reminders, sample) = try makeDatabase()
        let (open, close) = (Reminders.Highlight.open, Reminders.Highlight.close)
        let page = try results(Reminders.Query(terms: ["take"], showCompleted: true), database)
        let walk = try #require(page.highlights[sample.reminders[3].id])
        #expect(walk.title == "\(open)Take\(close) a walk" && !walk.tags.contains(open) && !walk.notes.contains(open))
        #expect(page.highlights.count == page.rows.count)
        // "milk" is in the Groceries notes and in a title of the same list: the title ranks first.
        var milk = Reminder(id: Reminder.ID(UUID()), list: sample.lists[0].id, title: "Milk run", created: now)
        milk = try await reminders.create(milk, below: nil).reminder
        let ranked = try results(Reminders.Query(terms: ["milk"], showCompleted: true), database)
        #expect(ranked.rows.map(\.title) == ["Milk run", "Groceries"])
        #expect(ranked.highlights[milk.id]?.title == "\(open)Milk\(close) run")
        #expect(ranked.highlights[sample.reminders[0].id]?.notes.contains("\(open)Milk\(close)") == true)
        #expect(try results(Reminders.Query(tags: ["car"], showCompleted: true), database).highlights.isEmpty)
    }

    @Test func `Today and the completed set are read through indexes, not a scan of every reminder`() async throws {
        let (database, _, _) = try makeDatabase()
        let today = try plan(Reminder.Record.where { $0.isDue(by: self.today) }.rows(), database)
        #expect(today.contains { $0.contains("idx_reminders_due") }, "\(today)")
        let completed = try plan(Reminder.Record.where { $0.isCompleted }.select(\.id), database)
        #expect(completed.contains { $0.contains("idx_reminders_completed") }, "\(completed)")
        let tags = try plan(
            Tag<Reminder>.Record.group(by: \.title).leftJoin(Reminders.Tagging.all) { $0.title.collate(.binary).eq($1.tagID.text) }.select { ($0.title, $1.reminderID.count()) },
            database
        )
        #expect(tags.contains { $0.contains("SEARCH remindersTags USING") && $0.contains("idx_remindersTags_tagID") }, "\(tags)")
        #expect(try overview(database).counts.today == 3)
        #expect(try detail(.today, database).rows.map(\.title) == ["Haircut", "Buy concert tickets", "Doctor appointment"])
    }
}

extension Reminders.Page {
    var reminders: [Reminder] { rows }
}
