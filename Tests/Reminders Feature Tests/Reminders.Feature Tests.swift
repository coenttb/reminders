import Clocks
import ComposableArchitecture2
import ComposableArchitectureTestSupport
import DebugSnapshots
import Dependencies
import DependenciesTestSupport
import FoundationEssentials_Extensions
import Foundation
import Observation
import Models
import Reminder
import Reminders
import Reminders_Sample
import Reminders_Dependency
import Reminders_Feature
import Reminders_SQL
import Reminders_SQLite
import Sharing
import SQLiteData
import Synchronization
import Testing
import Tagged

@Suite(.dependencies {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    $0.calendar = calendar
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
struct `Reminder feature` {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    @Dependency(\.defaultDatabase) var database

    typealias Listing = Reminders.Listing.Feature
    typealias Editor = Reminder.Editor.Feature

    let sample = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890))
    var personal: Models.List<Reminder>.ID { sample.lists[0].id }
    var groceries: Reminder { sample.reminders[0] }
    var today: Date { calendar.startOfDay(for: now) }
    var day: Range<Date> { calendar.day(containing: now)! }

    func makeStore(
        clock: TestClock<Duration> = TestClock(),
        restoring filter: Reminders.Filter? = nil,
        editing: Editor.State? = nil
    ) async throws -> TestStoreActor<Reminders.Feature> {
        // The initial state restores app storage, as a launch does.
        let store = await withDependencies { $0.continuousClock = clock } operation: {
            await TestStoreActor(initialState: Reminders.Feature.State()) { Reminders.Feature() }
        }
        if let filter {
            let listing = await store.state.listing
            #expect(listing?.filter == filter && listing?.editing == editing)
        }
        return store
    }


    var restoredFilter: Reminders.Filter? {
        @Shared(.appStorage(Reminders.Feature.filterKey)) var filter: Reminders.Filter.Key?
        return filter.flatMap(Reminders.Filter.init(key:))
    }

    func stored(_ id: Reminder.ID) async throws -> Reminder? {
        try await database.read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init) }
    }

    func row(_ id: Reminder.ID) async throws -> Reminders.Placement {
        try #require(try await database.read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Reminders.Placement.init) })
    }

    func block(_ event: String, on table: String, reason: String) async throws {
        try await database.write { db in
            try db.execute(sql: "CREATE TRIGGER block BEFORE \(event) ON \(table) BEGIN SELECT RAISE(ABORT, '\(reason)'); END")
        }
    }

    func unblock() async throws {
        try await database.write { db in try db.execute(sql: "DROP TRIGGER block") }
    }

    struct Deadline: Error {}

    func until<Value: Sendable>(_ fetch: Fetch<Value>, _ condition: @escaping @Sendable (Value) -> Bool) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await value in Observations({ fetch.wrappedValue }) where condition(value) { return }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                throw Deadline()
            }
            try await group.next()
            group.cancelAll()
        }
    }

    func page(_ store: TestStoreActor<Reminders.Feature>) async throws -> Fetch<Reminders.Page> {
        try #require(await store.state.listing?.$page)
    }

    func editing(_ store: TestStoreActor<Reminders.Feature>) async throws -> Editor.State {
        try #require(await store.state.listing?.editing)
    }

    func form(_ store: TestStoreActor<Reminders.Feature>) async -> Reminder.Form.Feature.State? {
        await store.state.destination.flatMap { if case let .reminder(form) = $0 { form } else { nil } }
    }

    @Test func `completing a reminder finishes after the grace period and everything persists`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        await store.send(.overview(.listTapped(personal)))?.value
        let grace = await store.send(.listing(.reminderCompleteButtonTapped(groceries.id)))
        #expect(await store.state.listing?.grace == [groceries.id: UUID(0)])
        #expect(try await stored(groceries.id)?.isCompleted == false)
        await clock.advance(by: .seconds(5))
        await grace?.value
        #expect(await store.state.listing?.grace == [:])
        #expect(try await stored(groceries.id)?.isCompleted == true)
        try await store.state.overview.$summary.load()
        await store.send(.newReminderButtonTapped)?.value
        #expect(await form(store)?.isNew == true)
        await store.modify {
            if case var .reminder(form) = $0.destination { form.draft.title = "Water plants"; $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.tagAdded("garden"))))?.value
        await store.send(.destination(.reminder(.tagAdded("ADULTING"))))?.value
        #expect(await form(store)?.draft.tags == ["garden", "adulting"])
        await store.send(.destination(.reminder(.saveButtonTapped)))?.value
        #expect(await store.state.destination == nil)
        await store.send(.listing(.orderingSelected(.title)))?.value
        await store.send(.listing(.directionSelected(.reverse)))?.value
        await store.send(.listing(.showCompletedButtonTapped))?.value
        await store.dismount()
        let saved = try await database.read { db in try Reminder.Record.where { $0.title.eq("Water plants") }.rows().fetchOne(db) }
        #expect(saved?.reminder.title == "Water plants" && saved?.reminder.position == 11)
        #expect(saved.map { Reminder($0).tags } == ["garden", "adulting"])
        let adulting = try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).count { $0.title.lowercased() == "adulting" } }
        #expect(adulting == 1)
        #expect(restoredFilter == .list(personal))
        let preference = try await database.read { [personal] db in try Reminders.Preference.Record.find(Reminders.Filter.Key(.list(personal))).fetchOne(db) }
        #expect(preference?.ordering == .title && preference?.direction == .reverse && preference?.showCompleted == true)
        }
    }

    @Test func `the screens read the database and follow writes made elsewhere`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await store.state.overview.$summary.load()
        #expect(await store.state.overview.summary.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(await store.state.overview.summary.counts == Reminders.Summary.Counts(all: 8, flagged: 2, scheduled: 7, today: 3))
        await store.send(.overview(.listTapped(personal)))?.value
        #expect(await store.state.listing?.page.rows.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        try await until(store.state.overview.$summary) { $0.counts.all == 7 }
        try await until(try await page(store)) { $0.rows.count == 3 }
        #expect(await store.state.overview.summary.lists.first?.count == 3)
        await store.dismount()
        }
    }

    @Test func `typing in a row is a draft until Return writes it and continues beneath, and Done drops a blank row`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.newReminderButtonTapped))?.value
        let editing = try await editing(store)
        let first = editing.id
        #expect(await store.state.listing?.window == Window(key: .list(personal), rows: nil, step: Listing.paging.step, margin: Listing.paging.margin))
        #expect(editing.isSaved && editing.draft.isBlank && editing.draft.list == personal && editing.place.position == 11 && editing.session == UUID(0))
        #expect(try await stored(first)?.isBlank == true)
        try await until(try await page(store)) { $0.rows.map(\.id).contains(first) == true }
        await store.modify { $0.listing?.editing?.draft.title = "Milk" }?.value
        #expect(try await stored(first)?.title == "")
        #expect(await store.state.listing?.editing?.isSaved == false)
        await store.send(.listing(.editing(.titleSubmitted)))?.value
        let next = try await self.editing(store)
        let second = next.id
        #expect(second != first && next.session == UUID(2) && next.draft.isBlank && next.isSaved)
        #expect(next.place.reminder.title == "Milk" && next.place.reminder.id == second && next.place.position == 12)
        // The next row is shown beneath its anchor at once, before the page carries it.
        #expect(next.anchor == first)
        #expect(await store.state.listing?.contents.rows.map(\.id).suffix(2) == [first, second])
        try await until(try await page(store)) { $0.rows.map(\.id).suffix(2) == [first, second] }
        #expect(try await stored(first)?.title == "Milk")
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        #expect(try await stored(second) == nil)
        await store.dismount()
        }
    }

    @Test func `a relaunch never reopens a card: a blank draft left by a kill is dropped, a written one is a plain row`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.newReminderButtonTapped))?.value
        let blank = try await editing(store).id
        // A relaunch is a new store over the same database; the first process is gone without a dismount.
        let revived = try await makeStore(restoring: .list(personal))
        #expect(await revived.state.listing?.editing == nil)
        try await until(try await page(revived)) { !$0.rows.contains { $0.id == blank } }
        #expect(try await stored(blank) == nil)
        await revived.send(.listing(.newReminderButtonTapped))?.value
        await revived.modify { $0.listing?.editing?.draft.title = "Kept" }?.value
        let kept = try await editing(revived).id
        await revived.send(.listing(.doneButtonTapped))?.value
        try await until(try await page(revived)) { $0.rows.contains { $0.id == kept && $0.title == "Kept" } }
        await store.dismount()
        await revived.dismount()
        let relaunched = try await makeStore(restoring: .list(personal))
        #expect(await relaunched.state.listing?.editing == nil)
        #expect(try await stored(kept)?.title == "Kept")
        await relaunched.dismount()
        }
    }

    @Test func `a long filter is read a window at a time, widened near its end, and whole when a row starts at its end`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let scale = Reminders.Sample.Scale(lists: 1, remindersPerList: 700, tags: 5)
        let generated = Reminders.Sample.generated(scale, seed: 1, at: now, calendar: calendar)
        try await database.write { db in try generated.replace(in: db) }
        let list = generated.lists[0].id
        let open = generated.reminders.count { !$0.isCompleted }
        let step = Listing.paging.step
        #expect(open > step && open < 2 * step)
        let store = try await makeStore()
        await store.send(.overview(.filterTapped(.all)))?.value
        try await until(try await page(store)) { $0.rows.count == step }
        #expect(await store.state.listing?.page.total == open)
        await store.send(.listing(.endReached))?.value
        #expect(await store.state.listing?.window == Window(key: .all, rows: 2 * step, step: step, margin: Listing.paging.margin))
        try await until(try await page(store)) { $0.rows.count == open }
        await store.send(.listing(.endReached))?.value
        await store.send(.overview(.listTapped(list)))?.value
        try await until(try await page(store)) { $0.rows.count == step }
        await store.send(.listing(.newReminderButtonTapped))?.value
        let editing = try await editing(store)
        #expect(await store.state.listing?.window == Window(key: .list(list), rows: nil, step: Listing.paging.step, margin: Listing.paging.margin))
        #expect(editing.place.position == 700 && editing.draft.list == list)
        try await until(try await page(store)) { $0.rows.count == open + 1 && $0.rows.map(\.id).last == editing.id }
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        await store.dismount()
        }
    }

    @Test func `a relaunch onto an open list reads its rows`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.dismount()
        let revived = try await makeStore(restoring: .list(personal))
        try await until(try await page(revived)) { $0.rows.count == 4 }
        await revived.dismount()
        }
    }

    @Test func `a commit that fails keeps the row open with its draft, and the next commit tries the whole difference again`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.reminderTapped(groceries.id)))?.value
        let expected = Editor.State(try await row(groceries.id), session: UUID(0))
        #expect(try await editing(store) == expected)
        try await block("UPDATE OF title", on: "reminders", reason: "title locked")
        await store.modify { $0.listing?.editing?.draft.title = "Groceries!" }?.value
        var editing = try await editing(store)
        #expect(editing.draft.title == "Groceries!" && editing.original.title == "Groceries" && !editing.isSaved)
        #expect(editing.failure == nil)
        await store.send(.listing(.doneButtonTapped))?.value
        editing = try await self.editing(store)
        #expect(editing.failure?.contains("title locked") == true)
        #expect(await store.state.failure?.contains("title locked") == true)
        #expect(try await stored(groceries.id) == groceries)
        await store.send(.listing(.reminderTapped(sample.reminders[1].id)))?.value
        await store.send(.listing(.reminderDetailsButtonTapped(groceries.id)))?.value
        editing = try await self.editing(store)
        #expect(editing.id == groceries.id && editing.draft.title == "Groceries!")
        #expect(await store.state.destination == nil)
        await store.modify { $0.listing?.editing?.draft.notes = "Oat milk" }?.value
        #expect(try await stored(groceries.id) == groceries)
        try await unblock()
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        let saved = try await stored(groceries.id)
        #expect(saved?.title == "Groceries!" && saved?.notes == "Oat milk")
        await store.dismount()
        }
    }

    @Test func `a commit writes the form's columns last and never brings a deleted row back`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.reminderTapped(groceries.id)))?.value
        let expected = Editor.State(try await row(groceries.id), session: UUID(0))
        #expect(try await editing(store) == expected)
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }
        await store.modify { $0.listing?.editing?.draft.title = "Groceries and more" }?.value
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        let saved = try await stored(groceries.id)
        #expect(saved?.title == "Groceries and more")
        #expect(saved?.flagged == false)
        await store.send(.listing(.reminderTapped(groceries.id)))?.value
        let reopened = Editor.State(try await row(groceries.id), session: UUID(1))
        #expect(try await editing(store) == reopened)
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        await store.modify { $0.listing?.editing?.draft.title = "Back" }?.value
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        #expect(try await stored(groceries.id) == nil)
        await store.dismount()
        }
    }

    @Test func `the inline chips run the domain rules on the feature's clock and are written when editing ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.newReminderButtonTapped))?.value
        let row = try await editing(store).id
        await store.send(.listing(.editing(.datePresetSelected(.tomorrow))))?.value
        await store.send(.listing(.editing(.timePresetSelected(.evening))))?.value
        let draft = try await editing(store).draft
        let due = try #require(draft.due)
        #expect(due.hasTime)
        #expect(calendar.isDate(due.date, inSameDayAs: now.addingTimeInterval(.day)))
        #expect(calendar.component(.hour, from: due.date) == 18)
        #expect(try await stored(row)?.due == nil)
        await store.send(.listing(.editing(.timePresetSelected(nil))))?.value
        #expect(try await editing(store).draft.due?.hasTime == false)
        await store.modify { $0.listing?.editing?.draft.title = "Call" }?.value
        let dated = try await editing(store).draft
        await store.send(.listing(.doneButtonTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        #expect(try await stored(row) == dated)
        await store.dismount()
        }
    }

    @Test func `submitting the search commits the text as a token and the results follow`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.modify { $0.search.field.text = "Take" }
        await store.send(.search(.submitted))?.value
        let state = await store.state
        #expect(state.search.field.tokens == [.near("Take")])
        #expect(state.search.field.text.isEmpty)
        try await store.state.overview.$summary.load()
        #expect(await store.state.results.titles == ["Take out trash"])
        #expect(await store.state.results.completedCount == 1)
        await store.send(.search(.completedButtonTapped))?.value
        #expect(await store.state.search.field.showCompleted)
        #expect(await store.state.results.titles == ["Take a walk", "Take out trash"])
        await store.dismount()
        }
    }

    @Test func `typing in the search is read once after a pause, and a cleared field at once`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        try await store.state.overview.$summary.load()
        await store.modify { $0.search.field.text = "Tak" }
        let typed = await store.modify { $0.search.field.text = "Take" }
        await clock.advance(by: Reminders.Search.Feature.pause - .milliseconds(1))
        #expect(await store.state.results.titles.isEmpty)
        await clock.advance(by: .milliseconds(1))
        await typed?.value
        #expect(await store.state.results.titles == ["Take out trash"])
        await store.modify { $0.search.field.text = "" }?.value
        #expect(await store.state.results.titles.isEmpty)
        await store.dismount()
        }
    }

    @Test func `a second tap inside the grace period takes the first back without a write`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        await store.send(.overview(.listTapped(personal)))?.value
        let grace = await store.send(.listing(.reminderCompleteButtonTapped(groceries.id)))
        #expect(await store.state.listing?.grace == [groceries.id: UUID(0)])
        await clock.advance(by: .seconds(2))
        await store.send(.listing(.reminderCompleteButtonTapped(groceries.id)))?.value
        #expect(await store.state.listing?.grace == [:])
        try await block("UPDATE OF completed", on: "reminders", reason: "completion locked")
        await clock.advance(by: .seconds(5))
        await grace?.value
        #expect(try await stored(groceries.id)?.isCompleted == false)
        #expect(await store.state.failure == nil)
        try await unblock()
        await store.dismount()
        }
    }

    @Test func `taps on several rows all finish, five seconds after the last tap`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        await store.send(.overview(.listTapped(personal)))?.value
        try await until(try await page(store)) { $0.rows.count == 4 }
        let rows = try await page(store).wrappedValue.rows.map(\.id)
        for id in rows.prefix(3) {
            await store.send(.listing(.reminderCompleteButtonTapped(id)))
            await clock.advance(by: .seconds(1))
        }
        #expect(await store.state.listing?.gracing == Set(rows.prefix(3)))
        // The first tap was six seconds ago, the last one four: nothing is written yet.
        await clock.advance(by: .seconds(3))
        #expect(try await stored(rows[0])?.isCompleted == false)
        await clock.advance(by: .seconds(2))
        try await until(try await page(store)) { $0.rows.count == 1 }
        for id in rows.prefix(3) { #expect(try await stored(id)?.isCompleted == true) }
        #expect(await store.state.listing?.grace == [:])
        await store.dismount()
        }
    }

    @Test func `a completed reminder is reopened at once, and leaving the feature writes what is still in grace`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        let walk = sample.reminders[3]
        await store.send(.overview(.listTapped(personal)))?.value
        try await until(try await page(store)) { $0.rows.isEmpty == false }
        await store.send(.listing(.showCompletedButtonTapped))?.value
        try await until(try await page(store)) { $0.rows.map(\.id).contains(walk.id) == true }
        await store.send(.listing(.reminderCompleteButtonTapped(walk.id)))?.value
        #expect(try await stored(walk.id)?.isCompleted == false)
        await store.send(.listing(.reminderCompleteButtonTapped(groceries.id)))
        #expect(await store.state.listing?.grace == [groceries.id: UUID(0)])
        await store.dismount()
        #expect(try await stored(groceries.id)?.isCompleted == true)
        }
    }

    @Test func `a grace period that ends does not touch a newer editing session`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        let haircut = sample.reminders[1]
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.reminderTapped(groceries.id)))?.value
        #expect(try await editing(store).session == UUID(0))
        let grace = await store.send(.listing(.reminderCompleteButtonTapped(groceries.id)))
        #expect(await store.state.listing?.grace == [groceries.id: UUID(1)])
        let haircutRow = try await row(haircut.id)
        await store.send(.listing(.reminderTapped(haircut.id)))?.value
        #expect(try await editing(store) == Editor.State(haircutRow, session: UUID(2)))
        await clock.advance(by: .seconds(5))
        await grace?.value
        #expect(await store.state.listing?.grace == [:])
        #expect(try await stored(groceries.id)?.isCompleted == true)
        let editing = try await editing(store)
        #expect(editing.id == haircut.id && editing.session == UUID(2) && editing.draft == haircutRow.reminder)
        await store.send(.listing(.doneButtonTapped))?.value
        await store.dismount()
        }
    }

    @Test func `a tap on the empty part of a list starts a row or ends editing, and leaving the detail ends it`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.backgroundTapped))?.value
        let editing = try await editing(store)
        let row = editing.id
        #expect(await store.state.listing?.window == Window(key: .list(personal), rows: nil, step: Listing.paging.step, margin: Listing.paging.margin))
        #expect(editing.draft.isBlank && editing.place.position == 11 && editing.session == UUID(0))
        await store.modify { $0.listing?.editing?.draft.title = "Bread" }?.value
        await store.send(.listing(.backgroundTapped))?.value
        #expect(await store.state.listing?.editing == nil)
        let bread = try await self.row(row)
        #expect(bread.reminder.title == "Bread")
        await store.send(.listing(.reminderTapped(row)))?.value
        #expect(try await self.editing(store) == Editor.State(bread, session: UUID(2)))
        await store.modify { $0.listing?.editing?.draft.notes = "Rye" }?.value
        // Popping the listing dismounts it; the draft is written on the way out.
        await store.modify { $0.listing = nil }?.value
        #expect(try await stored(row)?.notes == "Rye")
        #expect(restoredFilter == nil)
        await store.dismount()
        }
    }

    @Test func `details from a row ends editing and opens the sheet on the stored reminder`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        let groceriesRow0 = try await row(groceries.id)
        await store.send(.listing(.reminderTapped(groceries.id)))?.value
        await store.modify { $0.listing?.editing?.draft.title = "Groceries and more" }?.value
        var committed = groceriesRow0.reminder
        committed.title = "Groceries and more"
        await store.send(.listing(.reminderDetailsButtonTapped(groceries.id)))?.value
        #expect(await store.state.listing?.editing == nil)
        #expect(await form(store)?.draft == committed)
        #expect(await form(store)?.original == committed)
        await store.send(.destination(.reminder(.cancelButtonTapped)))?.value
        #expect(await store.state.destination == nil)
        let (haircut, doctor) = (sample.reminders[1], sample.reminders[2])
        await store.send(.listing(.reminderTapped(haircut.id)))?.value
        let expected = Editor.State(try await row(haircut.id), session: UUID(1))
        #expect(try await editing(store) == expected)
        await store.send(.listing(.reminderTapped(doctor.id)))?.value
        let doctorRow = Editor.State(try await row(doctor.id), session: UUID(2))
        #expect(try await editing(store) == doctorRow)
        await store.send(.listing(.reminderTapped(doctor.id)))?.value
        await store.dismount()
        }
    }

    @Test func `Custom on a blank row names it, dates it today, and opens the Date & Time sheet; a drop onto a section dates the row`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.backgroundTapped))?.value
        let row = try #require(await store.state.listing?.editing?.id)
        await store.send(.listing(.editing(.customDateTapped)))?.value
        #expect(await form(store)?.part == .dates)
        #expect(await form(store)?.draft.title == "New Reminder")
        #expect(await form(store)?.draft.due == .day(calendar.startOfDay(for: now)))
        #expect(try await stored(row)?.title == "New Reminder")
        await store.send(.destination(.reminder(.cancelButtonTapped)))?.value
        await store.send(.listing(.reminderDropped(row, into: .tomorrow)))?.value
        try await until(try await page(store)) { $0.rows.first { $0.id == row }?.due == .day(calendar.startOfDay(for: now).addingTimeInterval(.day)) }
        await store.dismount()
        }
    }

    @Test func `a deleted reminder waits in Recently Deleted, where it is recovered or deleted for good, and goes after thirty days`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await store.state.overview.$summary.load()
        #expect(await store.state.overview.summary.counts.deleted == 0)
        await store.send(.overview(.listTapped(personal)))?.value
        await store.send(.listing(.reminderDeleted(groceries.id)))?.value
        try await until(store.state.overview.$summary) { $0.counts.deleted == 1 && $0.counts.all == 7 }
        #expect(try await stored(groceries.id)?.deleted == now)
        await store.send(.overview(.filterTapped(.recentlyDeleted)))?.value
        try await until(try await page(store)) { $0.rows.map(\.id) == [groceries.id] }
        await store.send(.listing(.reminderRecovered(groceries.id)))?.value
        try await until(try await page(store)) { $0.rows.isEmpty }
        #expect(try await stored(groceries.id)?.isDeleted == false)
        try await database.write { db in try Reminder.Record.find(groceries.id).update { $0.deleted = #bind(now) }.execute(db) }
        try await until(try await page(store)) { $0.rows.map(\.id) == [groceries.id] }
        await store.send(.listing(.reminderDeleted(groceries.id)))?.value
        try await until(try await page(store)) { $0.rows.isEmpty }
        #expect(try await stored(groceries.id) == nil)
        // The purge on activation drops what was deleted more than thirty days ago.
        let haircut = sample.reminders[1]
        try await database.write { db in try Reminder.Record.find(haircut.id).update { $0.deleted = #bind(now.addingTimeInterval(-Reminder.retention - 1)) }.execute(db) }
        await store.send(.appActivated)?.value
        try await until(store.state.overview.$summary) { $0.counts.deleted == 0 }
        #expect(try await stored(haircut.id) == nil)
        await store.dismount()
        }
    }

    @Test func `deleting the last list leaves a default one and closes its detail`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        let ids = sample.lists.map(\.id)
        await store.send(.overview(.listTapped(ids[0])))?.value
        await store.send(.listing(.listDeleteButtonTapped))?.value
        #expect(await store.state.listing == nil)
        await store.send(.overview(.listDeleted(ids[1])))?.value
        await store.send(.overview(.listDeleted(ids[2])))?.value
        try await until(store.state.overview.$summary) { $0.lists.map(\.list.title) == ["Personal"] }
        let overview = await store.state.overview.summary
        #expect(overview.lists.first?.id == Models.List<Reminder>.ID(UUID(2)))
        #expect(overview.counts.all == 0)
        await store.dismount()
        }
    }

    @Test func `the grace period between the tap and completed is five seconds`() {
        #expect(Listing.grace == .seconds(5))
    }

    @Test func `an editing session starts saved and knows when the draft differs`() {
        let reminder = Reminder(id: groceries.id, list: personal, title: "Groceries", tags: ["car"], created: now)
        var editing = Editor.State(Reminders.Placement(reminder, position: 4), session: UUID())
        #expect(editing.isSaved && editing.id == reminder.id && editing.place.reminder.tags == ["car"] && editing.place.position == 4)
        editing.draft.title = "Call back"
        #expect(!editing.isSaved && editing.original == reminder)
    }

    @Test func `the list form edits a list, Done is one save, and the reminder form's tag intents change every reminder`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await store.state.overview.$summary.load()
        let family = sample.lists[1]
        await store.send(.overview(.listDetailsButtonTapped(family.id)))?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.draft.title = "Home"; $0.destination = .list(form) }
        }?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.isSaving = true; $0.destination = .list(form) }
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(try await database.read { db in try Models.List<Reminder>.Record.find(family.id).fetchOne(db)?.title } == "Family")
        await store.modify {
            if case var .list(form) = $0.destination { form.isSaving = false; $0.destination = .list(form) }
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(await store.state.destination == nil)
        #expect(try await database.read { db in try Models.List<Reminder>.Record.find(family.id).fetchOne(db)?.title } == "Home")
        await store.send(.overview(.listTapped(personal)))?.value
        let groceriesRow = try await row(groceries.id)
        await store.send(.listing(.reminderDetailsButtonTapped(groceries.id)))?.value
        #expect(await form(store)?.draft == groceriesRow.reminder)
        #expect(await form(store)?.original == groceriesRow.reminder)
        await store.send(.destination(.reminder(.tagRenamed("someday", "later"))))?.value
        #expect(await form(store)?.draft.tags.contains("later") == true)
        #expect(await form(store)?.draft.tags.contains("someday") == false)
        await store.send(.destination(.reminder(.tagDeleted("optional"))))?.value
        #expect(await form(store)?.draft.tags.contains("optional") == false)
        await store.send(.destination(.reminder(.cancelButtonTapped)))?.value
        #expect(try await database.read { db in try Reminders.Tagging.where { $0.tagID.eq(Tag<Reminder>("later")) }.fetchCount(db) } == 2)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("optional") == false)
        await store.dismount()
        }
    }

    @Test func `a tag intent that fails is the form's failure and leaves its draft and the tags alone`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await store.state.overview.$summary.load()
        await store.send(.overview(.tagTapped("car")))?.value
        await store.send(.listing(.reminderDetailsButtonTapped(groceries.id)))?.value
        try await block("INSERT", on: "tags", reason: "tags locked")
        await store.send(.destination(.reminder(.tagAdded("garden"))))?.value
        #expect(await form(store)?.failure?.contains("tags locked") == true)
        #expect(await form(store)?.draft.tags == groceries.tags)
        try await unblock()
        try await block("DELETE", on: "tags", reason: "tags kept")
        await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
        #expect(await form(store)?.failure?.contains("tags kept") == true)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 7)
        #expect(await store.state.listing?.filter == .tags(["car"]))
        try await unblock()
        try await block("UPDATE", on: "tags", reason: "tags fixed")
        await store.send(.destination(.reminder(.tagRenamed("car", "auto"))))?.value
        #expect(await form(store)?.failure?.contains("tags fixed") == true)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("car"))
        try await unblock()
        #expect(await store.state.failure == nil)
        await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
        #expect(await store.state.listing == nil)
        #expect(await form(store)?.failure == nil)
        await store.dismount()
        }
    }

    @Test func `search tokens, the completed toggle, and clearing`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await store.state.overview.$summary.load()
        await store.send(.search(.tagTapped("car")))?.value
        #expect(await store.state.search.field.tokens == [.tag("car")])
        await store.send(.search(.completedButtonTapped))?.value
        await store.send(.search(.deleteCompletedButtonTapped(olderThanMonths: nil)))?.value
        #expect(try await database.read { db in try Reminder.Record.where { $0.isKept }.fetchCount(db) } == 10)
        await store.modify { $0.search.field.tokens = [] }?.value
        #expect(await store.state.search.field.showCompleted == false)
        await store.send(.overview(.tagTapped("car")))?.value
        #expect(await store.state.listing?.filter == .tags(["car"]))
        await store.send(.overview(.tagDeleted("car")))?.value
        #expect(await store.state.listing == nil)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        await store.dismount()
        }
    }

    @Test func `a form with a blank title does not save, and a failed save keeps the draft`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.addListButtonTapped)?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(try await database.read { db in try Models.List<Reminder>.Record.all.fetchCount(db) } == 3)
        await store.send(.destination(.list(.cancelButtonTapped)))?.value
        try await until(store.state.overview.$summary) { !$0.lists.isEmpty }
        await store.send(.newReminderButtonTapped)?.value
        #expect(await form(store)?.draft == Reminder(id: Reminder.ID(UUID(1)), list: personal, created: now))
        await store.modify {
            if case var .reminder(form) = $0.destination { form.draft.title = "Orphan"; $0.destination = .reminder(form) }
        }?.value
        try await database.write { [personal] db in try Models.List<Reminder>.Record.find(personal).delete().execute(db) }
        await store.send(.destination(.reminder(.saveButtonTapped)))?.value
        let failed = await form(store)
        #expect(failed?.failure?.contains("FOREIGN KEY") == true)
        #expect(failed?.draft.title == "Orphan")
        #expect(failed?.isSaving == false)
        #expect(try await database.read { db in try Reminder.Record.where { $0.title.eq("Orphan") }.fetchCount(db) } == 0)
        await store.send(.destination(.reminder(.cancelButtonTapped)))?.value
        let trash = sample.reminders[7]
        await store.send(.overview(.listTapped(trash.list)))?.value
        await store.send(.listing(.reminderDetailsButtonTapped(trash.id)))?.value
        #expect(await form(store)?.draft.id == trash.id)
        try await database.write { db in try Reminder.Record.find(trash.id).delete().execute(db) }
        await store.send(.destination(.reminder(.saveButtonTapped)))?.value
        #expect(await form(store)?.failure == "This reminder was deleted.")
        #expect(try await stored(trash.id) == nil)
        await store.dismount()
        }
    }

    static let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
    static let tokyoClock = TestClock()
    static let tokyoDate = Mutex(Date(timeIntervalSince1970: 1_234_567_890))

    @Test(.dependencies {
        $0.calendar = tokyo
        $0.continuousClock = tokyoClock
        $0.date = DateGenerator { tokyoDate.withLock { $0 } }
    })
    func `the day changes on the clock at midnight and on activation, by the feature's calendar`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let clock = Self.tokyoClock
        let tokyo = Self.tokyo
        let start = Date(timeIntervalSince1970: 1_234_567_890)
        Self.tokyoDate.withLock { $0 = start }
        let day = tokyo.day(containing: start)!
        #expect(day.lowerBound == tokyo.date(from: DateComponents(year: 2009, month: 2, day: 14)))
        let store = try await makeStore(clock: clock)
        #expect(await store.state.today == day.lowerBound)
        await store.send(.overview(.filterTapped(.today)))?.value
        try await until(try await page(store)) { $0.rows.map(\.title) == ["Haircut", "Buy concert tickets", "Doctor appointment"] }
        let untilMidnight = day.upperBound.timeIntervalSince(start)
        let next = try #require(tokyo.day(containing: day.upperBound))
        Self.tokyoDate.withLock { $0 = day.upperBound.addingTimeInterval(1) }
        await clock.advance(by: .seconds(untilMidnight))
        await store.expect { $0.today = next.lowerBound }
        #expect(await store.state.listing?.today == next.lowerBound)
        #expect(await store.state.overview.today == next.lowerBound)
        @Fetch(Reminders.Read.Today.Request(today: next.lowerBound)) var overview = Reminders.Summary()
        // Yesterday's rows are overdue now, so Today keeps them; the day boundary shows in the state above.
        try await until($overview) { $0.counts.today == 3 }
        try await until(try await page(store)) { $0.rows.count == 3 }
        let later = start.addingTimeInterval(2.days)
        Self.tokyoDate.withLock { $0 = later }
        await store.send(.appActivated) { $0.today = tokyo.startOfDay(for: later) }
        await store.dismount()
        }
    }

    @Test(.dependency(\.defaultDatabase, try DatabaseQueue()))
    func `a database that cannot be read is a failure, not a first run`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await withDependencies { $0.reminders = .sqlite($0.defaultDatabase) } operation: { try await makeStore() }
        // The failure surfaces from the overview read that mounting starts.
        for _ in 0..<100 where await store.state.failure == nil { try await Task.sleep(for: .milliseconds(20)) }
        #expect(await store.state.failure?.contains("no such table") == true)
        await store.dismount()
        #expect(try await database.read { db in try db.tableExists("lists") } == false)
        }
    }

    @Test(.dependencies { try $0.bootstrapDatabase() })
    func `the first run installs the default list`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        try await until(store.state.overview.$summary) { $0.lists.map(\.list.title) == ["Personal"] && $0.counts.all == 0 }
        await store.dismount()
        }
    }

    @Test func `a launch restores the open filter from app storage and forgets a list that is gone`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        @Shared(.appStorage(Reminders.Feature.filterKey)) var filter: Reminders.Filter.Key?
        $filter.withLock { $0 = Reminders.Filter.Key(.list(personal)) }
        let store = try await makeStore(restoring: .list(personal))
        #expect(await store.state.listing?.editing == nil)
        #expect(await store.state.failure == nil)
        #expect(restoredFilter == .list(personal))
        await store.dismount()
        // A list that is gone takes the launch back to the front screen and forgets the filter.
        $filter.withLock { $0 = Reminders.Filter.Key(.list(Models.List<Reminder>.ID(UUID()))) }
        let fronted = try await makeStore()
        let front = await fronted.state
        #expect(front.listing == nil && front.failure == nil)
        #expect(restoredFilter == nil)
        await fronted.dismount()
        $filter.withLock { $0 = Reminders.Filter.Key(.tags(["someday", "nothing"])) }
        let retagged = try await makeStore()
        let untagged = await retagged.state.listing
        #expect(untagged == nil && restoredFilter == nil)
        await retagged.dismount()
        $filter.withLock { $0 = Reminders.Filter.Key(.completed) }
        let completed = try await makeStore(restoring: .completed)
        await completed.dismount()
        }
    }
}

extension Reminders.Search.Contents {
    var titles: [String] { sections.flatMap(\.rows).map(\.title) }
}
