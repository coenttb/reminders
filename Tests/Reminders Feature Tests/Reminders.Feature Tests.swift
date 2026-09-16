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

    let sample = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890))
    var personal: List<Reminder>.ID { sample.lists[0].id }
    var groceries: Reminder { sample.reminders[0] }
    var today: Range<Date> { calendar.day(containing: now)! }

    func makeStore(
        clock: TestClock<Duration> = TestClock(),
        restoring: @escaping @Sendable (inout Reminders.Feature.State.DebugSnapshot) -> Void = { _ in }
    ) async throws -> TestStoreActor<Reminders.Feature> {
        await withDependencies { $0.continuousClock = clock } operation: {
            await TestStoreActor(initialState: Reminders.Feature.State()) { Reminders.Feature() } changes: { [today] in
                $0.today = today
                restoring(&$0)
            }
        }
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

    @Test func `completing a reminder finishes after the grace period and everything persists`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        @Fetch(Reminders.Pending.Request()) var pending: Set<Reminder.ID> = []
        await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        #expect(try await stored(groceries.id)?.completed == true)
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completed == true)
        await store.send(.newReminderButtonTapped) { [personal, now] in
            $0.destination = .reminder(snap(Reminder.Form.Feature.State(draft: Reminder(id: Reminder.ID(UUID(0)), list: personal, created: now), original: nil)))
        }?.value
        await store.modify {
            if case var .reminder(form) = $0.destination { form.draft.title = "Water plants"; $0.destination = .reminder(form) }
        } changes: {
            if case var .reminder(form) = $0.destination { form.draft.title = "Water plants"; $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.tagAdded("garden")))) {
            if case var .reminder(form) = $0.destination { form.draft.tags.insert("garden"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.tagAdded("ADULTING")))) {
            if case var .reminder(form) = $0.destination { form.draft.tags.insert("adulting"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.saveButtonTapped))) { $0.destination = nil }?.value
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.orderingSelected(.title))?.value
        await store.send(.showCompletedButtonTapped)?.value
        await store.dismount()
        let saved = try await database.read { db in try Reminder.Record.where { $0.title.eq("Water plants") }.rows().fetchOne(db) }
        #expect(saved?.reminder.title == "Water plants" && saved?.reminder.position == 11)
        #expect(saved.map { Reminder($0).tags } == ["garden", "adulting"])
        let adulting = try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).count { $0.title.lowercased() == "adulting" } }
        #expect(adulting == 1)
        let restored = try await database.read { db in try Reminders.Session.Record.current.fetchOne(db) }
        #expect(restored?.filter == Reminders.Filter.Key(.list(personal)))
        let preference = try await database.read { [personal] db in try Reminders.Filter.Preference.Record.preference(for: .list(personal)).fetchOne(db) }
        #expect(preference?.ordering == .title && preference?.showCompleted == true)
    }

    @Test func `the screens read the database and follow writes made elsewhere`() async throws {
        let store = try await makeStore()
        try await store.state.$overview.load()
        #expect(await store.state.overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(await store.state.overview.counts == Reminders.Overview.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        #expect(await store.state.detail?.rows.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        try await until(store.state.$overview) { $0.counts.all == 7 }
        try await until(store.state.$detail) { $0?.rows.count == 3 }
        #expect(await store.state.overview.lists.first?.count == 3)
        await store.dismount()
    }

    @Test func `typing in a row is a draft until Return writes it and continues beneath, and Done drops a blank row`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
            await store.send(.newReminderButtonTapped)?.value
            let editing = try #require(await store.state.editing)
            let first = editing.id
            #expect(await store.state.detailWindow == Window(key: .list(personal), rows: nil, step: Reminders.Feature.paging.step, margin: Reminders.Feature.paging.margin))
            #expect(editing.isSaved && editing.draft.isBlank && editing.draft.list == personal && editing.place.position == 11 && editing.session == UUID(0))
            #expect(try await stored(first)?.isBlank == true)
            try await until(store.state.$detail) { $0?.ids.contains(first) == true }
            await store.modify { $0[draft: first]?.title = "Milk" }?.value
            #expect(try await stored(first)?.title == "")
            #expect(await store.state.editing?.isSaved == false)
            await store.send(.titleSubmitted)?.value
            let next = try #require(await store.state.editing)
            let second = next.id
            #expect(second != first && next.session == UUID(1) && next.draft.isBlank && next.isSaved)
            #expect(next.place.reminder.title == "Milk" && next.place.reminder.id == second && next.place.position == 12)
            try await until(store.state.$detail) { $0?.ids.suffix(2) == [first, second] }
            #expect(try await stored(first)?.title == "Milk")
            await store.send(.doneButtonTapped) { $0.editing = nil }?.value
            #expect(try await stored(second) == nil)
            #expect(try await database.read { db in try Reminders.Session.Record.current.fetchOne(db)?.editing } == nil)
            await store.dismount()
        }
    }

    @Test func `a relaunch reopens the row that was being edited`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
            await store.send(.newReminderButtonTapped)?.value
            let row = try #require(await store.state.editing?.id)
            await store.dismount()
            #expect(try await database.read { db in try Reminders.Session.Record.current.fetchOne(db)?.editing } == row)
            let revived = try await makeStore { [personal] in $0.filter = .list(personal) }
            let editing = try #require(await revived.state.editing)
            #expect(editing.id == row && editing.draft.isBlank && editing.isSaved && editing.session == UUID(1))
            await revived.send(.filterTapped(.today)) {
                $0.filter = .today
                $0.editing = nil
            }?.value
            #expect(try await database.read { db in try Reminders.Session.Record.current.fetchOne(db)?.editing } == nil)
            await revived.dismount()
        }
    }

    @Test func `a long filter is read a window at a time, widened near its end, and whole when a row starts at its end`() async throws {
        let scale = Reminders.Sample.Scale(lists: 1, remindersPerList: 700, tags: 5)
        let generated = Reminders.Sample.generated(scale, seed: 1, at: now, calendar: calendar)
        try await database.write { db in try generated.replace(in: db) }
        let list = generated.lists[0].id
        let open = generated.reminders.count { !$0.completed }
        let step = Reminders.Feature.paging.step
        #expect(open > step && open < 2 * step)
        let store = try await makeStore()
        await store.send(.filterTapped(.all)) { $0.filter = .all }?.value
        try await until(store.state.$detail) { $0?.filter == .all && $0?.rows.count == step }
        #expect(await store.state.detail?.total == open)
        await store.send(.detailEndReached) { $0.detailWindow = Window(key: .all, rows: 2 * step, step: step, margin: Reminders.Feature.paging.margin) }?.value
        try await until(store.state.$detail) { $0?.rows.count == open }
        await store.send(.detailEndReached)?.value
        await store.send(.listTapped(list)) { $0.filter = .list(list) }?.value
        try await until(store.state.$detail) { $0?.filter == .list(list) && $0?.rows.count == step }
        try await TestExhaustivity.$current.withValue(.off) {
            await store.send(.newReminderButtonTapped)?.value
            let editing = try #require(await store.state.editing)
            #expect(await store.state.detailWindow == Window(key: .list(list), rows: nil, step: Reminders.Feature.paging.step, margin: Reminders.Feature.paging.margin))
            #expect(editing.place.position == 700 && editing.draft.list == list)
            try await until(store.state.$detail) { $0?.rows.count == open + 1 && $0?.ids.last == editing.id }
            await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        }
        await store.dismount()
    }

    @Test func `a relaunch onto an open list reads its rows`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.dismount()
        let revived = try await makeStore { [personal] in $0.filter = .list(personal) }
        try await until(revived.state.$detail) { $0?.filter == .list(personal) && $0?.rows.count == 4 }
        await revived.dismount()
    }

    @Test func `a commit that fails keeps the row open with its draft, and the next commit tries the whole difference again`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
            let groceriesRow0 = try await row(groceries.id)
            await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceriesRow0, session: UUID(0)) }?.value
            try await block("UPDATE OF title", on: "reminders", reason: "title locked")
            await store.modify { $0[draft: groceries.id]?.title = "Groceries!" }?.value
            var editing = try #require(await store.state.editing)
            #expect(editing.draft.title == "Groceries!" && editing.original.title == "Groceries" && !editing.isSaved)
            #expect(editing.failure == nil)
            await store.send(.doneButtonTapped)?.value
            editing = try #require(await store.state.editing)
            #expect(editing.failure?.contains("title locked") == true)
            #expect(await store.state.failure?.contains("title locked") == true)
            #expect(try await stored(groceries.id) == groceries)
            await store.send(.reminderTapped(sample.reminders[1].id))?.value
            await store.send(.reminderDetailsButtonTapped(groceries.id))?.value
            editing = try #require(await store.state.editing)
            #expect(editing.id == groceries.id && editing.draft.title == "Groceries!")
            #expect(await store.state.destination == nil)
            await store.modify { $0[draft: groceries.id]?.notes = "Oat milk" }?.value
            #expect(try await stored(groceries.id) == groceries)
            try await unblock()
            await store.send(.doneButtonTapped)?.value
            #expect(await store.state.editing == nil)
            let saved = try await stored(groceries.id)
            #expect(saved?.title == "Groceries!" && saved?.notes == "Oat milk")
            await store.dismount()
        }
    }

    @Test func `a commit writes the form's columns last and never brings a deleted row back`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let groceriesRow0 = try await row(groceries.id)
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceriesRow0, session: UUID(0)) }?.value
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }
        await store.modify { $0[draft: groceries.id]?.title = "Groceries and more" } changes: { $0.editing?.draft.title = "Groceries and more" }?.value
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        let saved = try await stored(groceries.id)
        #expect(saved?.title == "Groceries and more")
        #expect(saved?.flagged == false)
        let groceriesRow1 = try await row(groceries.id)
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceriesRow1, session: UUID(1)) }?.value
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        await store.modify { $0[draft: groceries.id]?.title = "Back" } changes: { $0.editing?.draft.title = "Back" }?.value
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        #expect(try await stored(groceries.id) == nil)
        await store.modify { $0[draft: groceries.id]?.title = "Late" }?.value
        #expect(try await stored(groceries.id) == nil)
        await store.dismount()
    }

    @Test func `the inline chips run the domain rules on the feature's clock and are written when editing ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.newReminderButtonTapped)?.value
        let row = try #require(await store.state.editing?.id)
        await store.send(.datePresetSelected(row, .tomorrow)) { [now, calendar] in
            $0.editing?.draft.set(datePreset: .tomorrow, at: now, calendar: calendar)
        }?.value
        await store.send(.timePresetSelected(row, .evening)) { [now, calendar] in
            $0.editing?.draft.set(timePreset: .evening, at: now, calendar: calendar)
        }?.value
        let draft = try #require(await store.state.editing?.draft)
        let due = try #require(draft.due)
        #expect(due.hasTime)
        #expect(calendar.isDate(due.date, inSameDayAs: now.addingTimeInterval(.day)))
        #expect(calendar.component(.hour, from: due.date) == 18)
        #expect(try await stored(row)?.due == nil)
        await store.send(.timePresetSelected(row, nil)) { [now, calendar] in
            $0.editing?.draft.set(timePreset: nil, at: now, calendar: calendar)
        }?.value
        #expect(await store.state.editing?.draft.due?.hasTime == false)
        await store.modify { $0[draft: row]?.title = "Call" } changes: { $0.editing?.draft.title = "Call" }?.value
        let dated = try #require(await store.state.editing?.draft)
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        #expect(try await stored(row) == dated)
        await store.dismount()
        }
    }

    @Test func `submitting the search commits the text as a token and the results follow`() async throws {
        let store = try await makeStore()
        await store.modify { $0.search.text = "Take" } changes: { $0.search.text = "Take" }
        await store.send(.searchSubmitted) { $0.search.commitText() }?.value
        let state = await store.state
        #expect(state.search.tokens == [.near("Take")])
        #expect(state.search.text.isEmpty)
        #expect(state.results.titles == ["Take out trash"])
        #expect(state.results.completedCount == 1)
        await store.send(.searchCompletedButtonTapped) { $0.search.showCompleted = true }?.value
        #expect(await store.state.results.titles == ["Take a walk", "Take out trash"])
        await store.dismount()
    }

    @Test func `typing in the search is read once after a pause, and a cleared field at once`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        await store.modify { $0.search.text = "Tak" } changes: { $0.search.text = "Tak" }
        let typed = await store.modify { $0.search.text = "Take" } changes: { $0.search.text = "Take" }
        await clock.advance(by: Reminders.Feature.searchPause - .milliseconds(1))
        #expect(await store.state.results.titles.isEmpty)
        await clock.advance(by: .milliseconds(1))
        await typed?.value
        #expect(await store.state.results.titles == ["Take out trash"])
        await store.modify { $0.search.text = "" } changes: { $0.search.text = "" }?.value
        #expect(await store.state.results.titles.isEmpty)
        await store.dismount()
    }

    @Test func `a second tap restarts the grace period, a reversal is not undone, and a quit mid-period resumes it`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        @Fetch(Reminders.Pending.Request()) var pending: Set<Reminder.ID> = []
        let (haircut, doctor) = (sample.reminders[1].id, sample.reminders[2].id)
        await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        await clock.advance(by: .seconds(4))
        await store.send(.reminderCompleteButtonTapped(haircut))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id, haircut] }
        await clock.advance(by: .seconds(4))
        #expect(try await stored(groceries.id)?.completed == true)
        #expect(try await stored(haircut)?.completed == true)
        await clock.advance(by: .seconds(1))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completed == true)
        #expect(try await stored(haircut)?.completed == true)
        await store.send(.reminderCompleteButtonTapped(doctor))?.value
        try await until($pending) { $0 == [doctor] }
        await clock.advance(by: .seconds(2))
        await store.send(.reminderCompleteButtonTapped(doctor))?.value
        try await until($pending) { $0.isEmpty }
        await clock.advance(by: .seconds(5))
        #expect(try await stored(doctor)?.completed == false)
        await store.dismount()
        try await database.write { db in try Reminder.Record.toggle(doctor).execute(db) }
        try await until($pending) { $0 == [doctor] }
        let revived = try await makeStore(clock: clock)
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(doctor)?.completed == true)
        await revived.dismount()
    }

    @Test func `the grace period follows the table: a failed tap starts nothing, a deletion stops it, and another writer starts it`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let clock = TestClock()
            let store = try await makeStore(clock: clock)
            @Fetch(Reminders.Pending.Request()) var pending: Set<Reminder.ID> = []
            let haircut = sample.reminders[1].id
            try await block("UPDATE OF status", on: "reminders", reason: "status locked")
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            #expect(await store.state.failure?.contains("status locked") == true)
            #expect(await store.state.pending == [])
            try await unblock()
            await clock.advance(by: .seconds(5))
            #expect(try await stored(groceries.id)?.completed == false)
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            try await until($pending) { [groceries] in $0 == [groceries.id] }
            await clock.advance(by: .seconds(4))
            await store.send(.reminderDeleted(groceries.id))?.value
            try await until($pending) { $0.isEmpty }
            await clock.advance(by: .seconds(5))
            #expect(try await stored(groceries.id) == nil)
            try await database.write { db in try Reminder.Record.toggle(haircut).execute(db) }
            try await until($pending) { $0 == [haircut] }
            await clock.advance(by: .seconds(5))
            try await until($pending) { $0.isEmpty }
            #expect(try await stored(haircut)?.completed == true)
            await store.dismount()
        }
    }

    @Test func `a pending timer does not touch a newer editing session`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        @Fetch(Reminders.Pending.Request()) var pending: Set<Reminder.ID> = []
        let haircut = sample.reminders[1]
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let groceriesRow0 = try await row(groceries.id)
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceriesRow0, session: UUID(0)) }?.value
        await store.send(.reminderCompleteButtonTapped(groceries.id)) {
            $0.editing?.draft.completed = true
            $0.editing?.original.completed = true
        }?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        let haircutRow = try await row(haircut.id)
        await store.send(.reminderTapped(haircut.id)) { $0.editing = Reminder.Editing(haircutRow, session: UUID(1)) }?.value
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completed == true)
        let editing = try #require(await store.state.editing)
        #expect(editing.id == haircut.id && editing.session == UUID(1) && editing.draft == haircutRow.reminder)
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        await store.dismount()
    }

    @Test func `a tap on the empty part of a list starts a row or ends editing, and leaving the detail ends it`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            await store.send(.backgroundTapped)?.value
            #expect(await store.state.editing == nil)
            await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
            await store.send(.backgroundTapped)?.value
            let editing = try #require(await store.state.editing)
            let row = editing.id
            #expect(await store.state.detailWindow == Window(key: .list(personal), rows: nil, step: Reminders.Feature.paging.step, margin: Reminders.Feature.paging.margin))
            #expect(editing.draft.isBlank && editing.place.position == 11 && editing.session == UUID(0))
            await store.modify { $0[draft: row]?.title = "Bread" } changes: { $0.editing?.draft.title = "Bread" }?.value
            await store.send(.backgroundTapped) { $0.editing = nil }?.value
            let bread = try await self.row(row)
            #expect(bread.reminder.title == "Bread")
            await store.send(.reminderTapped(row)) { $0.editing = Reminder.Editing(bread, session: UUID(1)) }?.value
            await store.modify { $0[draft: row]?.notes = "Rye" } changes: { $0.editing?.draft.notes = "Rye" }?.value
            await store.send(.filterTapped(.today)) {
                $0.filter = .today
                $0.editing = nil
            }?.value
            #expect(try await stored(row)?.notes == "Rye")
            #expect(try await database.read { db in try Reminders.Session.Record.current.fetchOne(db)?.editing } == nil)
            await store.modify { $0[draft: row]?.title = "Late" }?.value
            #expect(try await stored(row)?.title == "Bread")
            await store.dismount()
        }
    }

    @Test func `details from a row ends editing and opens the sheet on the stored reminder`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let groceriesRow0 = try await row(groceries.id)
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceriesRow0, session: UUID(0)) }?.value
        await store.modify { $0[draft: groceries.id]?.title = "Groceries and more" } changes: { $0.editing?.draft.title = "Groceries and more" }?.value
        var committed = groceriesRow0.reminder
        committed.title = "Groceries and more"
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.editing = nil
            $0.destination = .reminder(snap(Reminder.Form.Feature.State(draft: committed, original: committed)))
        }?.value
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        let (haircut, doctor) = (sample.reminders[1], sample.reminders[2])
        let haircutRow1 = try await row(haircut.id)
        await store.send(.reminderTapped(haircut.id)) { $0.editing = Reminder.Editing(haircutRow1, session: UUID(1)) }?.value
        let doctorRow2 = try await row(doctor.id)
        await store.send(.reminderTapped(doctor.id)) { $0.editing = Reminder.Editing(doctorRow2, session: UUID(2)) }?.value
        await store.send(.reminderTapped(doctor.id))?.value
        #expect(try await database.read { db in try Reminders.Session.Record.current.fetchOne(db)?.editing } == doctor.id)
        await store.dismount()
    }

    @Test func `deleting the last list leaves a default one and closes its detail`() async throws {
        let store = try await makeStore()
        let ids = sample.lists.map(\.id)
        await store.send(.listTapped(ids[0])) { $0.filter = .list(ids[0]) }?.value
        await store.send(.listDeleted(ids[0])) { $0.filter = nil }?.value
        await store.send(.listDeleted(ids[1]))?.value
        await store.send(.listDeleted(ids[2]))?.value
        try await until(store.state.$overview) { $0.lists.map(\.list.title) == ["Personal"] }
        let overview = await store.state.overview
        #expect(overview.lists.first?.id == List<Reminder>.ID(UUID(2)))
        #expect(overview.counts.all == 0)
        await store.dismount()
    }

    @Test func `the grace period between the tap and completed is five seconds`() {
        #expect(Reminders.Feature.grace == .seconds(5))
    }

    @Test func `an editing session starts saved and knows when the draft differs`() {
        let reminder = Reminder(id: groceries.id, list: personal, title: "Groceries", tags: ["car"], created: now)
        var editing = Reminder.Editing(Reminders.Placement(reminder, position: 4), session: UUID())
        #expect(editing.isSaved && editing.id == reminder.id && editing.place.reminder.tags == ["car"] && editing.place.position == 4)
        editing.draft.title = "Call back"
        #expect(!editing.isSaved && editing.original == reminder)
    }

    @Test func `the list form edits a list, Done is one save, and the reminder form's tag intents change every reminder`() async throws {
        let store = try await makeStore()
        try await store.state.$overview.load()
        let family = sample.lists[1]
        await store.send(.listDetailsButtonTapped(family.id)) {
            $0.destination = .list(snap(List<Reminder>.Form.Feature.State(draft: family, original: family)))
        }?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.draft.title = "Home"; $0.destination = .list(form) }
        } changes: {
            if case var .list(form) = $0.destination { form.draft.title = "Home"; $0.destination = .list(form) }
        }?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.isSaving = true; $0.destination = .list(form) }
        } changes: {
            if case var .list(form) = $0.destination { form.isSaving = true; $0.destination = .list(form) }
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(try await database.read { db in try List<Reminder>.Record.find(family.id).fetchOne(db)?.title } == "Family")
        await store.modify {
            if case var .list(form) = $0.destination { form.isSaving = false; $0.destination = .list(form) }
        } changes: {
            if case var .list(form) = $0.destination { form.isSaving = false; $0.destination = .list(form) }
        }?.value
        await store.send(.destination(.list(.saveButtonTapped))) { $0.destination = nil }?.value
        #expect(try await database.read { db in try List<Reminder>.Record.find(family.id).fetchOne(db)?.title } == "Home")
        let groceriesRow = try await row(groceries.id)
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.destination = .reminder(snap(Reminder.Form.Feature.State(draft: groceriesRow.reminder, original: groceriesRow.reminder)))
        }?.value
        await store.send(.destination(.reminder(.tagRenamed("someday", "later")))) {
            if case var .reminder(form) = $0.destination {
                form.draft.tags.remove("someday")
                form.draft.tags.insert("later")
                $0.destination = .reminder(form)
            }
        }?.value
        await store.send(.destination(.reminder(.tagDeleted("optional")))) {
            if case var .reminder(form) = $0.destination { form.draft.tags.remove("optional"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        #expect(try await database.read { db in try Reminders.Tagging.where { $0.tagID.eq(Tag<Reminder>.ID("later")) }.fetchCount(db) } == 2)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("optional") == false)
        await store.dismount()
    }

    @Test func `a tag intent that fails is the form's failure and leaves its draft and the tags alone`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            try await store.state.$overview.load()
            await store.send(.tagTapped("car"))?.value
            await store.send(.reminderDetailsButtonTapped(groceries.id))?.value
            func form() async -> Reminder.Form.Feature.State? {
                await store.state.destination.flatMap { if case let .reminder(form) = $0 { form } else { nil } }
            }
            try await block("INSERT", on: "tags", reason: "tags locked")
            await store.send(.destination(.reminder(.tagAdded("garden"))))?.value
            #expect(await form()?.failure?.contains("tags locked") == true)
            #expect(await form()?.draft.tags == groceries.tags)
            try await unblock()
            try await block("DELETE", on: "tags", reason: "tags kept")
            await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
            #expect(await form()?.failure?.contains("tags kept") == true)
            #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 7)
            #expect(await store.state.filter == .tags(["car"]))
            try await unblock()
            try await block("UPDATE", on: "tags", reason: "tags fixed")
            await store.send(.destination(.reminder(.tagRenamed("car", "auto"))))?.value
            #expect(await form()?.failure?.contains("tags fixed") == true)
            #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("car"))
            try await unblock()
            #expect(await store.state.failure == nil)
            await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
            #expect(await store.state.filter == nil)
            #expect(await form()?.failure == nil)
            await store.dismount()
        }
    }

    @Test func `search tokens, the completed toggle, and clearing`() async throws {
        let store = try await makeStore()
        await store.send(.searchTagTapped("car")) { $0.search.add(tag: "car") }?.value
        await store.send(.searchCompletedButtonTapped) { $0.search.showCompleted = true }?.value
        await store.send(.deleteCompletedButtonTapped(olderThanMonths: nil))?.value
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 10)
        await store.modify { $0.search.tokens = [] } changes: {
            $0.search.tokens = []
            $0.search.showCompleted = false
        }?.value
        await store.send(.tagTapped("car")) { $0.filter = .tags(["car"]) }?.value
        await store.send(.tagDeleted("car")) { $0.filter = nil }?.value
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        await store.dismount()
    }

    @Test func `a form with a blank title does not save, and a failed save keeps the draft`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        await store.send(.addListButtonTapped) {
            $0.destination = .list(snap(List<Reminder>.Form.Feature.State(draft: List<Reminder>(id: List<Reminder>.ID(UUID(0))), original: nil)))
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(try await database.read { db in try List<Reminder>.Record.all.fetchCount(db) } == 3)
        await store.send(.destination(.list(.cancelButtonTapped))) { $0.destination = nil }?.value
        try await until(store.state.$overview) { !$0.lists.isEmpty }
        await store.send(.newReminderButtonTapped) { [personal, now] in
            $0.destination = .reminder(snap(Reminder.Form.Feature.State(draft: Reminder(id: Reminder.ID(UUID(1)), list: personal, created: now), original: nil)))
        }?.value
        await store.modify {
            if case var .reminder(form) = $0.destination { form.draft.title = "Orphan"; $0.destination = .reminder(form) }
        } changes: {
            if case var .reminder(form) = $0.destination { form.draft.title = "Orphan"; $0.destination = .reminder(form) }
        }?.value
        try await database.write { [personal] db in try List<Reminder>.Record.find(personal).delete().execute(db) }
        await store.send(.destination(.reminder(.saveButtonTapped)))?.value
        let failed = await store.state.destination.flatMap { if case let .reminder(form) = $0 { form } else { nil } }
        #expect(failed?.failure?.contains("FOREIGN KEY") == true)
        #expect(failed?.draft.title == "Orphan")
        #expect(failed?.isSaving == false)
        #expect(try await database.read { db in try Reminder.Record.where { $0.title.eq("Orphan") }.fetchCount(db) } == 0)
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        let trash = sample.reminders[7]
        let trashRow = try await row(trash.id)
        await store.send(.reminderDetailsButtonTapped(trash.id)) {
            $0.destination = .reminder(snap(Reminder.Form.Feature.State(draft: trashRow.reminder, original: trashRow.reminder)))
        }?.value
        try await database.write { db in try Reminder.Record.find(trash.id).delete().execute(db) }
        await store.send(.destination(.reminder(.saveButtonTapped))) {
            if case var .reminder(form) = $0.destination { form.failure = "This reminder was deleted."; $0.destination = .reminder(form) }
        }?.value
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
        let clock = Self.tokyoClock
        let tokyo = Self.tokyo
        let start = Date(timeIntervalSince1970: 1_234_567_890)
        Self.tokyoDate.withLock { $0 = start }
        let day = tokyo.day(containing: start)!
        #expect(day.lowerBound == tokyo.date(from: DateComponents(year: 2009, month: 2, day: 14)))
        let store = try await makeStore(clock: clock)
        #expect(await store.state.today == day)
        await store.send(.filterTapped(.today)) { $0.filter = .today }?.value
        try await until(store.state.$detail) { $0?.rows.map(\.title) == ["Doctor appointment", "Buy concert tickets"] }
        let untilMidnight = day.upperBound.timeIntervalSince(start)
        let next = try #require(tokyo.day(containing: day.upperBound))
        Self.tokyoDate.withLock { $0 = day.upperBound.addingTimeInterval(1) }
        await clock.advance(by: .seconds(untilMidnight))
        await store.expect { $0.today = next }
        @Fetch(Reminders.Overview.Request(today: next)) var overview = Reminders.Overview.Contents()
        try await until($overview) { $0.counts.today == 0 }
        try await until(store.state.$detail) { $0?.rows.isEmpty == true }
        let later = start.addingTimeInterval(2.days)
        Self.tokyoDate.withLock { $0 = later }
        await store.send(.appActivated) { $0.today = tokyo.day(containing: later)! }
        await store.dismount()
    }

    @Test(.dependency(\.defaultDatabase, try DatabaseQueue()))
    func `a database that cannot be read is a failure, not a first run`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await withDependencies { $0.reminders = .sqlite($0.defaultDatabase) } operation: { try await makeStore() }
            #expect(await store.state.failure?.contains("no such table") == true)
            await store.dismount()
        }
        #expect(try await database.read { db in try db.tableExists("lists") } == false)
    }

    @Test(.dependencies { try $0.bootstrapDatabase() })
    func `the first run installs the default list and the restoration row`() async throws {
        let store = try await makeStore()
        try await until(store.state.$overview) { $0.lists.map(\.list.title) == ["Personal"] && $0.counts.all == 0 }
        #expect(try await database.read { db in try Reminders.Session.Record.current.fetchCount(db) } == 1)
        await store.dismount()
    }
}

extension Reminders.Search.Contents {
    var titles: [String] { sections.flatMap(\.rows).map(\.title) }
}
