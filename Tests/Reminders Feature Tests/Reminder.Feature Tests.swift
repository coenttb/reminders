import Clocks
import ComposableArchitecture2
import ComposableArchitectureTestSupport
import DebugSnapshots
import Dependencies
import DependenciesTestSupport
import FoundationEssentials_Extensions
import Foundation
import Observation
import Organizing
import Reminders
import Reminders_Application
import Reminders_Feature
import Reminders_SQLiteData
import SQLiteData
import Synchronization
import Testing
import Tagged

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    $0.calendar = calendar
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
    // The database starts initialised with the sample, so the mount restores rather than seeds.
    try $0.defaultDatabase.write { db in try Reminder.sample(at: Date(timeIntervalSince1970: 1_234_567_890)).replace(in: db) }
})
struct `Reminder feature` {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    @Dependency(\.defaultDatabase) var database

    let sample = Reminder.sample(at: Date(timeIntervalSince1970: 1_234_567_890))
    var personal: List<Reminder>.ID { sample.lists[0].id }
    var groceries: Reminder { sample.reminders[0] }
    /// The day the feature computes at mount, by whatever calendar the test installed.
    var today: Range<Date> { calendar.day(containing: now)! }

    /// A mounted store on a clock the test controls; the mount sets the day, and restores
    /// whatever else the database says before anything else runs.
    func makeStore(
        clock: TestClock<Duration> = TestClock(),
        restoring: @escaping @Sendable (inout Reminder.Feature.State.DebugSnapshot) -> Void = { _ in }
    ) async throws -> TestStoreActor<Reminder.Feature> {
        try await withDependencies { $0.continuousClock = clock } operation: {
            try await TestStoreActor(initialState: Reminder.Feature.State()) { Reminder.Feature() } changes: { [today] in
                $0.today = today
                restoring(&$0)
            }
        }
    }

    func stored(_ id: Reminder.ID) async throws -> Reminder? {
        try await database.read { db in try Reminder.Record.find(id).rows().fetchOne(db)?.value }
    }

    /// Makes the next writes of a kind fail, as a database might: a trigger raising an error.
    func block(_ event: String, on table: String, reason: String) async throws {
        try await database.write { db in
            try db.execute(sql: "CREATE TRIGGER block BEFORE \(event) ON \(table) BEGIN SELECT RAISE(ABORT, '\(reason)'); END")
        }
    }

    func unblock() async throws {
        try await database.write { db in try db.execute(sql: "DROP TRIGGER block") }
    }

    struct Deadline: Error {}

    /// Waits until an observed query reads as required. A query is one shared reader per request
    /// and database, so a fetch made here of the feature's request is the feature's own
    /// observation: when it reads as required here, the feature has been told. A real-time
    /// deadline fails the test rather than hang it.
    func until<Value: Sendable>(_ fetch: Fetch<Value>, _ condition: @escaping @Sendable (Value) -> Bool) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                // The sequence begins with the current value, so a query that already reads as
                // required returns at once.
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
        @Fetch(Reminder.Completion.Pending.Request()) var pending = Reminder.Completion.Pending()
        await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        #expect(try await stored(groceries.id)?.completed == true)
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completion == .completed)
        // From the home the plus opens the sheet (inside a list it edits a row in place).
        let draft = Reminder(id: Reminder.ID(UUID(0)), list: personal, created: now)
        await store.send(.newReminderButtonTapped) {
            $0.destination = .reminder(snap(Reminder.Draft.Feature.State(reminder: draft, isNew: true, session: UUID(1))))
        }?.value
        await store.modify {
            if case var .reminder(form) = $0.destination { form.reminder.title = "Water plants"; $0.destination = .reminder(form) }
        } changes: {
            if case var .reminder(form) = $0.destination { form.draft.reminder.title = "Water plants"; $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.tagAdded("garden")))) {
            if case var .reminder(form) = $0.destination { form.draft.reminder.tags.insert("garden"); $0.destination = .reminder(form) }
        }?.value
        // A tag that exists in another case attaches the existing tag, not a twin.
        await store.send(.destination(.reminder(.tagAdded("ADULTING")))) {
            if case var .reminder(form) = $0.destination { form.draft.reminder.tags.insert("adulting"); $0.destination = .reminder(form) }
        }?.value
        // The sheet closes only once the write has landed.
        await store.send(.destination(.reminder(.saveButtonTapped))) { $0.destination = nil }?.value
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.orderingSelected(.title))?.value
        await store.send(.showCompletedButtonTapped)?.value
        await store.dismount()
        let saved = try await stored(draft.id)
        #expect(saved?.title == "Water plants")
        #expect(saved?.tags == ["garden", "adulting"])
        let adulting = try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).count { $0.title.lowercased() == "adulting" } }
        #expect(adulting == 1)
        let restored = try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.session }
        #expect(restored?.filter == .list(personal))
        let preference = try await database.read { [personal] db in try Reminder.Filter.Preference.Record.preference(for: .list(personal)).fetchOne(db)?.preference }
        #expect(preference == Reminder.Filter.Preference(ordering: .title, showCompleted: true))
    }

    @Test func `the screens read the database and follow writes made elsewhere`() async throws {
        let store = try await makeStore()
        try await store.state.$overview.load()
        #expect(await store.state.overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
        #expect(await store.state.overview.counts == Reminder.Filter.Counts(all: 8, flagged: 2, scheduled: 7, today: 2))
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        #expect(await store.state.detail?.reminders.map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        // Another writer deletes a reminder: the home and the detail both follow.
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        try await until(store.state.$overview) { $0.counts.all == 7 }
        try await until(store.state.$detail) { $0?.rows.count == 3 }
        #expect(await store.state.overview.lists.first?.count == 3)
        await store.dismount()
    }

    @Test func `typing in a row is written as it happens, Return continues beneath, and Done drops a blank row`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let first = Reminder.ID(UUID(0))
        let blank = Reminder(id: first, list: personal, position: 11, created: now)
        await store.send(.newReminderButtonTapped) { $0.editing = Reminder.Editing(blank, session: UUID(1)) }?.value
        // The new row is in the database at once, blank, and shown in the detail.
        #expect(try await stored(first)?.isBlank == true)
        try await until(store.state.$detail) { $0?.reminders.map(\.id).contains(first) == true }
        await store.modify { $0[draft: first].title = "Milk" } changes: {
            $0.editing?.draft.title = "Milk"
            $0.editing?.saved.title = "Milk"
        }?.value
        // Typing is stored without Done or a background: what the database holds is the draft.
        #expect(try await stored(first)?.title == "Milk")
        #expect(await store.state.editing?.isSaved == true)
        let second = Reminder.ID(UUID(2))
        var place = blank
        place.title = "Milk"
        place.id = second
        place.position = blank.position + 1
        let next = Reminder(id: second, list: personal, position: place.position, created: now)
        await store.send(.titleSubmitted) { $0.editing = Reminder.Editing(draft: next, saved: next, place: place, session: UUID(3)) }?.value
        try await until(store.state.$detail) { $0?.reminders.map(\.id).suffix(2) == [first, second] }
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        #expect(try await stored(second) == nil)
        #expect(try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.editing } == nil)
        await store.dismount()
    }

    @Test func `a relaunch in the middle of typing finds the text and reopens the row`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let row = Reminder.ID(UUID(0))
        let blank = Reminder(id: row, list: personal, position: 11, created: now)
        await store.send(.newReminderButtonTapped) { $0.editing = Reminder.Editing(blank, session: UUID(1)) }?.value
        await store.modify { $0[draft: row].title = "Bread" } changes: {
            $0.editing?.draft.title = "Bread"
            $0.editing?.saved.title = "Bread"
        }?.value
        // Quit without Done: the text and the row being edited are in the database.
        await store.dismount()
        #expect(try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.editing } == row)
        let bread = { var bread = blank; bread.title = "Bread"; return bread }()
        let revived = try await makeStore { [personal] in
            $0.filter = .list(personal)
            $0.editing = Reminder.Editing(bread, session: UUID(2))
        }
        #expect(await revived.state.editing?.draft.title == "Bread")
        // Leaving the detail, as the user, still ends the restored session.
        await revived.send(.filterTapped(.today)) {
            $0.filter = .today
            $0.editing = nil
        }?.value
        #expect(try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.editing } == nil)
        await revived.dismount()
    }

    @Test func `a relaunch onto an open list reads its rows`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.dismount()
        let revived = try await makeStore { [personal] in $0.filter = .list(personal) }
        try await until(revived.state.$detail) { $0?.filter == .list(personal) && $0?.rows.count == 4 }
        await revived.dismount()
    }

    @Test func `a write that fails keeps the draft and its baseline, and the next write tries the whole difference again`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
            await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceries, session: UUID(0)) }?.value
            try await block("UPDATE OF title", on: "reminders", reason: "title locked")
            await store.modify { $0[draft: groceries.id].title = "Groceries!" }?.value
            var editing = try #require(await store.state.editing)
            #expect(editing.draft.title == "Groceries!" && editing.saved == groceries && !editing.isSaved)
            #expect(editing.failure?.contains("title locked") == true)
            #expect(await store.state.failure?.contains("title locked") == true)
            #expect(try await stored(groceries.id) == groceries)
            // Done, another row, and Details all keep the row open rather than lose the text.
            await store.send(.doneButtonTapped)?.value
            await store.send(.reminderTapped(sample.reminders[1].id))?.value
            await store.send(.reminderDetailsButtonTapped(groceries.id))?.value
            editing = try #require(await store.state.editing)
            #expect(editing.id == groceries.id && editing.draft.title == "Groceries!")
            #expect(await store.state.destination == nil)
            // A change to another field waits with the title; the row still holds the fixture.
            await store.modify { $0[draft: groceries.id].notes = "Oat milk" }?.value
            #expect(try await stored(groceries.id) == groceries)
            try await unblock()
            await store.send(.doneButtonTapped)?.value
            #expect(await store.state.editing == nil)
            let saved = try await stored(groceries.id)
            #expect(saved?.title == "Groceries!" && saved?.notes == "Oat milk")
            await store.dismount()
        }
    }

    @Test func `typing keeps an external change to another field and never brings a deleted row back`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceries, session: UUID(0)) }?.value
        // Another writer flags the reminder meanwhile; the edit keeps the flag and changes the title.
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).update { $0.flagged = true }.execute(db) }
        await store.modify { $0[draft: groceries.id].title = "Groceries and more" } changes: {
            $0.editing?.draft.title = "Groceries and more"
            $0.editing?.saved.title = "Groceries and more"
        }?.value
        let saved = try await stored(groceries.id)
        #expect(saved?.title == "Groceries and more")
        #expect(saved?.flagged == true)
        // Deleted while its row is being edited: the next keystroke ends the session and recreates nothing.
        try await database.write { [groceries] db in try Reminder.Record.find(groceries.id).delete().execute(db) }
        await store.modify { $0[draft: groceries.id].title = "Back" } changes: { $0.editing = nil }?.value
        #expect(try await stored(groceries.id) == nil)
        // A binding write after editing ended is dropped.
        await store.modify { $0[draft: groceries.id].title = "Late" }?.value
        #expect(try await stored(groceries.id) == nil)
        await store.dismount()
    }

    @Test func `the inline chips run the domain rules on the feature's clock and are written at once`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let row = Reminder.ID(UUID(0))
        await store.send(.newReminderButtonTapped) { $0.editing = Reminder.Editing(Reminder(id: row, list: personal, position: 11, created: now), session: UUID(1)) }?.value
        await store.send(.datePresetSelected(row, .tomorrow)) { [now, calendar] in
            $0.editing?.draft.set(datePreset: .tomorrow, at: now, calendar: calendar)
            let draft = $0.editing!.draft
            $0.editing?.saved = draft
        }?.value
        await store.send(.timePresetSelected(row, .evening)) { [now, calendar] in
            $0.editing?.draft.set(timePreset: .evening, at: now, calendar: calendar)
            let draft = $0.editing!.draft
            $0.editing?.saved = draft
        }?.value
        let draft = try #require(await store.state.editing?.draft)
        let due = try #require(draft.due)
        #expect(due.hasTime)
        #expect(calendar.isDate(due.date, inSameDayAs: now.addingTimeInterval(.day)))
        #expect(calendar.component(.hour, from: due.date) == 18)
        #expect(try await stored(row) == draft)
        await store.send(.timePresetSelected(row, nil)) { [now, calendar] in
            $0.editing?.draft.set(timePreset: nil, at: now, calendar: calendar)
            let draft = $0.editing!.draft
            $0.editing?.saved = draft
        }?.value
        #expect(await store.state.editing?.draft.due?.hasTime == false)
        await store.dismount()
    }

    @Test func `submitting the search commits the text as a token and the results follow`() async throws {
        let store = try await makeStore()
        await store.modify { $0.search.text = "Take" } changes: { $0.search.text = "Take" }?.value
        await store.send(.searchSubmitted) { $0.search.commitText() }?.value
        let state = await store.state
        #expect(state.search.tokens == [.near("Take")])
        #expect(state.search.text.isEmpty)
        #expect(state.results.reminders.map(\.title) == ["Take out trash"])
        #expect(state.results.completedCount == 1)
        await store.send(.searchCompletedButtonTapped) { $0.search.showCompleted = true }?.value
        #expect(await store.state.results.reminders.map(\.title) == ["Take a walk", "Take out trash"])
        await store.dismount()
    }

    @Test func `a second tap restarts the grace period, a reversal is not undone, and a quit mid-period resumes it`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        @Fetch(Reminder.Completion.Pending.Request()) var pending = Reminder.Completion.Pending()
        let (haircut, doctor) = (sample.reminders[1].id, sample.reminders[2].id)
        await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        await clock.advance(by: .seconds(4))
        await store.send(.reminderCompleteButtonTapped(haircut))?.value
        try await until($pending) { [groceries] in $0 == [groceries.id, haircut] }
        await clock.advance(by: .seconds(4))
        // Eight seconds after the first tap nothing has completed: the second tap restarted the period.
        #expect(try await stored(groceries.id)?.completed == true)
        #expect(try await stored(haircut)?.completed == true)
        await clock.advance(by: .seconds(1))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completion == .completed)
        #expect(try await stored(haircut)?.completion == .completed)
        // A reversed tap is not completed by a stale timer.
        await store.send(.reminderCompleteButtonTapped(doctor))?.value
        try await until($pending) { $0 == [doctor] }
        await clock.advance(by: .seconds(2))
        await store.send(.reminderCompleteButtonTapped(doctor))?.value
        try await until($pending) { $0.isEmpty }
        await clock.advance(by: .seconds(5))
        #expect(try await stored(doctor)?.completion == .incomplete)
        await store.dismount()
        // A tap followed by a quit: the stored row still says completing, and the next mount finishes it.
        try await database.write { db in try Reminder.Record.toggle(doctor).execute(db) }
        try await until($pending) { $0 == [doctor] }
        let revived = try await makeStore(clock: clock)
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(doctor)?.completion == .completed)
        await revived.dismount()
    }

    @Test func `the grace period follows the table: a failed tap starts nothing, a deletion stops it, and another writer starts it`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let clock = TestClock()
            let store = try await makeStore(clock: clock)
            @Fetch(Reminder.Completion.Pending.Request()) var pending = Reminder.Completion.Pending()
            let haircut = sample.reminders[1].id
            // A tap whose write fails is reported, and no timer runs for it.
            try await block("UPDATE OF status", on: "reminders", reason: "status locked")
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            #expect(await store.state.failure?.contains("status locked") == true)
            #expect(await store.state.pending == [])
            try await unblock()
            await clock.advance(by: .seconds(5))
            #expect(try await stored(groceries.id)?.completion == .incomplete)
            // Rapid taps: the last change to the set is what the period is counted from.
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            await store.send(.reminderCompleteButtonTapped(groceries.id))?.value
            try await until($pending) { [groceries] in $0 == [groceries.id] }
            await clock.advance(by: .seconds(4))
            // Deleting the reminder in its grace period ends its period: nothing is left to complete.
            await store.send(.reminderDeleted(groceries.id))?.value
            try await until($pending) { $0.isEmpty }
            await clock.advance(by: .seconds(5))
            #expect(try await stored(groceries.id) == nil)
            // Another writer starts a grace period: the feature sees it and completes it in time.
            try await database.write { db in try Reminder.Record.toggle(haircut).execute(db) }
            try await until($pending) { $0 == [haircut] }
            await clock.advance(by: .seconds(5))
            try await until($pending) { $0.isEmpty }
            #expect(try await stored(haircut)?.completion == .completed)
            await store.dismount()
        }
    }

    @Test func `a pending timer does not touch a newer editing session`() async throws {
        let clock = TestClock()
        let store = try await makeStore(clock: clock)
        @Fetch(Reminder.Completion.Pending.Request()) var pending = Reminder.Completion.Pending()
        let haircut = sample.reminders[1]
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceries, session: UUID(0)) }?.value
        // The tap lands in the draft of the row it is on, and starts the period.
        await store.send(.reminderCompleteButtonTapped(groceries.id)) {
            $0.editing?.draft.completion = .completed
            $0.editing?.saved.completion = .completed
        }?.value
        try await until($pending) { [groceries] in $0 == [groceries.id] }
        // Another row opens while the period runs; when it ends, only the table changes.
        await store.send(.reminderTapped(haircut.id)) { $0.editing = Reminder.Editing(haircut, session: UUID(1)) }?.value
        await clock.advance(by: .seconds(5))
        try await until($pending) { $0.isEmpty }
        #expect(try await stored(groceries.id)?.completion == .completed)
        let editing = try #require(await store.state.editing)
        #expect(editing.id == haircut.id && editing.session == UUID(1) && editing.draft == haircut)
        await store.send(.doneButtonTapped) { $0.editing = nil }?.value
        await store.dismount()
    }

    @Test func `a tap on the empty part of a list starts a row or ends editing, and leaving the detail ends it`() async throws {
        let store = try await makeStore()
        await store.send(.backgroundTapped)?.value
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        let row = Reminder.ID(UUID(0))
        let blank = Reminder(id: row, list: personal, position: 11, created: now)
        await store.send(.backgroundTapped) { $0.editing = Reminder.Editing(blank, session: UUID(1)) }?.value
        await store.modify { $0[draft: row].title = "Bread" } changes: {
            $0.editing?.draft.title = "Bread"
            $0.editing?.saved.title = "Bread"
        }?.value
        await store.send(.backgroundTapped) { $0.editing = nil }?.value
        // The row reopens on the stored reminder, and leaving the detail ends the session.
        let bread = try #require(await stored(row))
        await store.send(.reminderTapped(row)) { $0.editing = Reminder.Editing(bread, session: UUID(2)) }?.value
        await store.modify { $0[draft: row].notes = "Rye" } changes: {
            $0.editing?.draft.notes = "Rye"
            $0.editing?.saved.notes = "Rye"
        }?.value
        await store.send(.filterTapped(.today)) {
            $0.filter = .today
            $0.editing = nil
        }?.value
        #expect(try await stored(row)?.notes == "Rye")
        #expect(try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.editing } == nil)
        // A binding write after editing ended is dropped.
        await store.modify { $0[draft: row].title = "Late" }?.value
        #expect(try await stored(row)?.title == "Bread")
        await store.dismount()
    }

    @Test func `details from a row ends editing and opens the sheet on the stored reminder`() async throws {
        let store = try await makeStore()
        await store.send(.listTapped(personal)) { $0.filter = .list(personal) }?.value
        await store.send(.reminderTapped(groceries.id)) { $0.editing = Reminder.Editing(groceries, session: UUID(0)) }?.value
        await store.modify { $0[draft: groceries.id].title = "Groceries and more" } changes: {
            $0.editing?.draft.title = "Groceries and more"
            $0.editing?.saved.title = "Groceries and more"
        }?.value
        var committed = groceries
        committed.title = "Groceries and more"
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.editing = nil
            $0.destination = .reminder(snap(Reminder.Draft.Feature.State(reminder: committed, isNew: false, session: UUID(1))))
        }?.value
        // Rapid row switching: each tap opens its own session on the stored row.
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        let (haircut, doctor) = (sample.reminders[1], sample.reminders[2])
        await store.send(.reminderTapped(haircut.id)) { $0.editing = Reminder.Editing(haircut, session: UUID(2)) }?.value
        await store.send(.reminderTapped(doctor.id)) { $0.editing = Reminder.Editing(doctor, session: UUID(3)) }?.value
        await store.send(.reminderTapped(doctor.id))?.value
        #expect(try await database.read { db in try Reminder.Session.Record.state.fetchOne(db)?.editing } == doctor.id)
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

    @Test func `the list form edits a list, Done is one save, and the reminder form's tag intents change every reminder`() async throws {
        let store = try await makeStore()
        try await store.state.$overview.load()
        let family = sample.lists[1]
        await store.send(.listDetailsButtonTapped(family.id)) {
            $0.destination = .list(snap(List<Reminder>.Draft.Feature.State(list: family, isNew: false, session: UUID(0))))
        }?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.list.title = "Home"; $0.destination = .list(form) }
        } changes: {
            if case var .list(form) = $0.destination { form.draft.list.title = "Home"; $0.destination = .list(form) }
        }?.value
        // Done while a save is under way is ignored: the writes are synchronous, so the state is
        // put in that condition here, and nothing is written for the second tap.
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
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.destination = .reminder(snap(Reminder.Draft.Feature.State(reminder: groceries, isNew: false, session: UUID(1))))
        }?.value
        await store.send(.destination(.reminder(.tagRenamed("someday", "later")))) {
            if case var .reminder(form) = $0.destination {
                form.draft.reminder.tags.remove("someday")
                form.draft.reminder.tags.insert("later")
                $0.destination = .reminder(form)
            }
        }?.value
        await store.send(.destination(.reminder(.tagDeleted("optional")))) {
            if case var .reminder(form) = $0.destination { form.draft.reminder.tags.remove("optional"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        #expect(try await database.read { db in try Reminder.Tagging.where { $0.tagID.eq(Tag<Reminder>.ID("later")) }.fetchCount(db) } == 2)
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("optional") == false)
        await store.dismount()
    }

    @Test func `a tag intent that fails is the form's failure and leaves its draft and the tags alone`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            try await store.state.$overview.load()
            await store.send(.tagTapped("car"))?.value
            await store.send(.reminderDetailsButtonTapped(groceries.id))?.value
            func form() async -> Reminder.Draft.Feature.State? {
                await store.state.destination.flatMap { if case let .reminder(form) = $0 { form } else { nil } }
            }
            try await block("INSERT", on: "tags", reason: "tags locked")
            await store.send(.destination(.reminder(.tagAdded("garden"))))?.value
            #expect(await form()?.failure?.contains("tags locked") == true)
            #expect(await form()?.reminder.tags == groceries.tags)
            try await unblock()
            try await block("DELETE", on: "tags", reason: "tags kept")
            await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
            #expect(await form()?.failure?.contains("tags kept") == true)
            #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 7)
            // The detail narrows only once the tag is gone.
            #expect(await store.state.filter == .tags(["car"]))
            try await unblock()
            try await block("UPDATE", on: "tags", reason: "tags fixed")
            await store.send(.destination(.reminder(.tagRenamed("car", "auto"))))?.value
            #expect(await form()?.failure?.contains("tags fixed") == true)
            #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchAll(db).map(\.title) }.contains("car"))
            try await unblock()
            // The failures belong to the form: the app's own failure stays clear.
            #expect(await store.state.failure == nil)
            await store.send(.destination(.reminder(.tagDeleted("car"))))?.value
            #expect(await store.state.filter == nil)
            #expect(await form()?.failure == nil)
            await store.dismount()
        }
    }

    @Test func `search tokens, the completed toggle, clearing, and the seed`() async throws {
        let store = try await makeStore()
        await store.send(.searchTagTapped("car")) { $0.search.add(tag: "car") }?.value
        await store.send(.searchCompletedButtonTapped) { $0.search.showCompleted = true }?.value
        await store.send(.deleteCompletedButtonTapped(olderThanMonths: nil))?.value
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 10)
        // Leaving search puts the completed toggle back.
        await store.modify { $0.search.tokens = [] } changes: {
            $0.search.tokens = []
            $0.search.showCompleted = false
        }?.value
        await store.send(.tagTapped("car")) { $0.filter = .tags(["car"]) }?.value
        await store.send(.tagDeleted("car")) { $0.filter = nil }?.value
        #expect(try await database.read { db in try Tag<Reminder>.Record.all.fetchCount(db) } == 6)
        await store.send(.seedButtonTapped)?.value
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 11)
        // A generated seed remembers itself and clears the seeding flag once written.
        let scale = Reminder.Sample.Scale(lists: 2, remindersPerList: 5, tags: 3)
        await store.send(.seedGenerated(scale, seed: 42)) {
            $0.lastSeed = Reminder.Sample.Seed(scale: scale, value: 42)
            $0.isSeeding = true
        }?.value
        await store.expect { $0.isSeeding = false }
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 10)
        await store.send(.deleteEverythingButtonTapped)?.value
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 0)
        #expect(try await database.read { db in try List<Reminder>.Record.all.fetchCount(db) } == 1)
        await store.dismount()
    }

    @Test func `a form with a blank title does not save, and a failed save keeps the draft`() async throws {
        // The message of a failed write is the database's; the save is asserted on its effects.
        try await TestExhaustivity.$current.withValue(.off) {
        let store = try await makeStore()
        let list = List<Reminder>(id: List<Reminder>.ID(UUID(0)))
        await store.send(.addListButtonTapped) {
            $0.destination = .list(snap(List<Reminder>.Draft.Feature.State(list: list, isNew: true, session: UUID(1))))
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(try await database.read { db in try List<Reminder>.Record.all.fetchCount(db) } == 3)
        await store.send(.destination(.list(.cancelButtonTapped))) { $0.destination = nil }?.value
        // A reminder whose list is deleted while its sheet is open cannot be saved: the draft stays.
        let draft = Reminder(id: Reminder.ID(UUID(2)), list: personal, title: "Orphan", created: now)
        await store.send(.newReminderButtonTapped) {
            $0.destination = .reminder(snap(Reminder.Draft.Feature.State(reminder: Reminder(id: draft.id, list: personal, created: now), isNew: true, session: UUID(3))))
        }?.value
        await store.modify {
            if case var .reminder(form) = $0.destination { form.reminder.title = "Orphan"; $0.destination = .reminder(form) }
        } changes: {
            if case var .reminder(form) = $0.destination { form.draft.reminder.title = "Orphan"; $0.destination = .reminder(form) }
        }?.value
        try await database.write { [personal] db in try List<Reminder>.Record.find(personal).delete().execute(db) }
        await store.send(.destination(.reminder(.saveButtonTapped)))?.value
        let failed = await store.state.destination.flatMap { if case let .reminder(form) = $0 { form } else { nil } }
        #expect(failed?.failure?.contains("FOREIGN KEY") == true)
        #expect(failed?.reminder.title == "Orphan")
        #expect(failed?.isSaving == false)
        #expect(try await stored(draft.id) == nil)
        // A stored reminder deleted while its sheet is open is not recreated by Done.
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        let trash = sample.reminders[7]
        await store.send(.reminderDetailsButtonTapped(trash.id)) {
            $0.destination = .reminder(snap(Reminder.Draft.Feature.State(reminder: trash, isNew: false, session: UUID(4))))
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

    // The calendar, clock, and date are the test's own from the start, through the trait, so
    // every task the feature runs sees them.
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
        // 2009-02-13 23:31:30 UTC is 08:31 on the 14th in Tokyo: the day is Tokyo's, whatever the process time zone.
        let day = tokyo.day(containing: start)!
        #expect(day.lowerBound == tokyo.date(from: DateComponents(year: 2009, month: 2, day: 14)))
        let store = try await makeStore(clock: clock)
        #expect(await store.state.today == day)
        await store.send(.filterTapped(.today)) { $0.filter = .today }?.value
        try await until(store.state.$detail) { $0?.reminders.map(\.title) == ["Doctor appointment", "Buy concert tickets"] }
        // Midnight, Tokyo time, with no write anywhere: the day, the count, and the detail move on.
        let untilMidnight = day.upperBound.timeIntervalSince(start)
        let next = try #require(tokyo.day(containing: day.upperBound))
        Self.tokyoDate.withLock { $0 = day.upperBound.addingTimeInterval(1) }
        await clock.advance(by: .seconds(untilMidnight))
        // The task of a day change is the next midnight timer: it is not awaited, the dismount cancels it.
        await store.expect { $0.today = next }
        @Fetch(Reminder.Overview.Request(today: next)) var overview = Reminder.Overview()
        try await until($overview) { $0.counts.today == 0 }
        try await until(store.state.$detail) { $0?.rows.isEmpty == true }
        // Coming back to the foreground days later reads the day again without waiting for the clock.
        let later = start.addingTimeInterval(2.days)
        Self.tokyoDate.withLock { $0 = later }
        await store.send(.appActivated) { $0.today = tokyo.day(containing: later)! }
        await store.dismount()
    }

    @Test(.dependency(\.defaultDatabase, try DatabaseQueue()))
    func `a database that cannot be read is a failure, not a first run`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = try await makeStore()
            #expect(await store.state.failure?.contains("no such table") == true)
            await store.dismount()
        }
        #expect(try await database.read { db in try db.tableExists("lists") } == false)
    }

    @Test(.dependency(\.defaultDatabase, try { let db = try Reminder.Schema.inMemoryDatabase(); return db }()))
    func `the first run seeds the sample into an empty database`() async throws {
        let store = try await makeStore()
        try await until(store.state.$overview) { $0.counts.all == 8 }
        await store.dismount()
    }
}
