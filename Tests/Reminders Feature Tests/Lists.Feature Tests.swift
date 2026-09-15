import ComposableArchitecture2
import ComposableArchitectureTestSupport
import DebugSnapshots
import Dependencies
import DependenciesTestSupport
import Foundation
import Reminders
import Reminders_Feature
import Reminders_SQLiteData
import SQLiteData
import Clocks
import Testing
import Tagged

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    $0.calendar = Calendar(identifier: .gregorian)
    $0.continuousClock = ImmediateClock()
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
})
struct `Lists feature` {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    /// The mount seeds the sample into the empty test database; starting from the same
    /// value keeps that seeding out of the exhaustive assertions.
    func makeStore() async -> TestStoreActor<Lists.Feature> {
        await TestStoreActor(initialState: Lists.Feature.State(lists: Lists.sample(at: now))) { Lists.Feature() }
    }

    @Test func `completing a reminder finishes after the grace period and everything persists`() async throws {
        let store = await makeStore()
        let lists = await store.state.lists
        let groceries = lists.reminders[0].id
        let personal = lists.orderedLists[0].id
        await store.send(.reminderCompleteButtonTapped(groceries)) { $0.lists.toggle(groceries) }?.value
        await store.expect { $0.lists.completeCompleting() }?.value
        // From the home the plus opens the sheet (inside a list it edits a row in place).
        let draft = Reminder(id: Reminder.ID(UUID(0)), list: personal)
        await store.send(.newReminderButtonTapped) {
            $0.destination = .reminder(snap(Reminder.Feature.State(reminder: draft, isNew: true)))
        }?.value
        await store.modify {
            if case var .reminder(form) = $0.destination { form.reminder.title = "Water plants"; $0.destination = .reminder(form) }
        } changes: {
            if case var .reminder(form) = $0.destination { form.reminder.title = "Water plants"; $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.tagAdded("garden")))) {
            $0.lists.add(tag: "garden")
            if case var .reminder(form) = $0.destination { form.reminder.tags.insert("garden"); $0.destination = .reminder(form) }
        }?.value
        // A tag that exists in another case attaches the existing tag, not a twin.
        await store.send(.destination(.reminder(.tagAdded("ADULTING")))) {
            if case var .reminder(form) = $0.destination { form.reminder.tags.insert("adulting"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.saveButtonTapped))) {
            var saved = draft
            saved.title = "Water plants"
            saved.tags = ["garden", "adulting"]
            $0.lists.upsert(saved)
            $0.destination = nil
        }?.value
        await store.send(.listTapped(personal)) { $0.lists.detail = .list(personal) }?.value
        await store.send(.orderingSelected(.title)) { $0.lists.set(ordering: .title, for: .list(personal)) }?.value
        await store.send(.showCompletedButtonTapped) { $0.lists.toggleShowCompleted(for: .list(personal)) }?.value
        await store.dismount()
        @Dependency(\.defaultDatabase) var database
        let stored = try await database.read { db in try Lists.load(db) }
        #expect(stored?.reminder(groceries)?.status == .completed)
        #expect(stored?.detail == .list(personal))
        #expect(stored?.preference(for: .list(personal)) == Lists.Detail.Preference(ordering: .title, showCompleted: true))
        #expect(stored?.reminders.last?.title == "Water plants")
        #expect(stored?.reminders.last?.tags == ["garden", "adulting"])
        #expect(stored?.tags.filter { $0.title.lowercased() == "adulting" }.count == 1)
    }

    @Test func `inline editing in a list commits the titled row and drops the blank one`() async throws {
        let store = await makeStore()
        let personal = await store.state.lists.orderedLists[0].id
        await store.send(.listTapped(personal)) { $0.lists.detail = .list(personal) }?.value
        let first = Reminder.ID(UUID(0))
        await store.send(.newReminderButtonTapped) { $0.lists.startNewReminder(in: personal, id: first) }?.value
        await store.modify { $0.lists[draft: first].title = "Milk" } changes: { $0.lists[draft: first].title = "Milk" }?.value
        let second = Reminder.ID(UUID(1))
        await store.send(.titleSubmitted) { $0.lists.continueEditing(id: second) }?.value
        await store.send(.doneButtonTapped) { $0.lists.endEditing() }?.value
        let lists = await store.state.lists
        #expect(lists.editing == nil && lists.reminder(second) == nil && lists.reminder(first)?.title == "Milk")
        await store.dismount()
        @Dependency(\.defaultDatabase) var database
        let stored = try await database.read { db in try Lists.load(db) }
        #expect(stored?.reminder(first)?.title == "Milk")
        #expect(stored?.editing == nil)
    }

    @Test func `the inline chips run the domain rules on the feature's clock`() async throws {
        let store = await makeStore()
        let personal = await store.state.lists.orderedLists[0].id
        await store.send(.listTapped(personal)) { $0.lists.detail = .list(personal) }?.value
        let row = Reminder.ID(UUID(0))
        await store.send(.newReminderButtonTapped) { $0.lists.startNewReminder(in: personal, id: row) }?.value
        await store.send(.datePresetSelected(row, .tomorrow)) { $0.lists.set(datePreset: .tomorrow, for: row, at: now, calendar: calendar) }?.value
        await store.send(.timePresetSelected(row, .evening)) { $0.lists.set(timePreset: .evening, for: row, at: now, calendar: calendar) }?.value
        let reminder = try #require(await store.state.lists.reminder(row))
        #expect(reminder.hasTime && calendar.isDate(reminder.due!, inSameDayAs: now.addingTimeInterval(86_400)) && calendar.component(.hour, from: reminder.due!) == 18)
        await store.send(.timePresetSelected(row, nil)) { $0.lists.set(timePreset: nil, for: row, at: now, calendar: calendar) }?.value
        #expect(await store.state.lists.reminder(row)?.hasTime == false)
        await store.dismount()
    }

    @Test func `submitting the search commits the text as a token`() async throws {
        let store = await makeStore()
        await store.modify { $0.search.text = "Take" } changes: { $0.search.text = "Take" }?.value
        await store.send(.searchSubmitted) { $0.search.commitText() }?.value
        let state = await store.state
        #expect(state.search.tokens == [.near("Take")] && state.search.text.isEmpty)
        #expect(state.lists.matches(state.search).map(\.title) == ["Take out trash", "Take a walk"])
        await store.dismount()
    }

    @Test func `a second tap restarts the grace period and a quit mid-period resumes it`() async throws {
        let clock = TestClock()
        let store = await withDependencies { $0.continuousClock = clock } operation: { await makeStore() }
        let lists = await store.state.lists
        let (groceries, haircut, doctor) = (lists.reminders[0].id, lists.reminders[1].id, lists.reminders[2].id)
        // The task a send returns holds its timer, so it is awaited only once that timer is over.
        let first = await store.send(.reminderCompleteButtonTapped(groceries)) { $0.lists.toggle(groceries) }
        await clock.advance(by: .seconds(4))
        let second = await store.send(.reminderCompleteButtonTapped(haircut)) { $0.lists.toggle(haircut) }
        await first?.value
        await clock.advance(by: .seconds(4))
        // Eight seconds after the first tap nothing has completed: the second tap restarted the period.
        #expect(await store.state.lists.completing == [groceries, haircut])
        await clock.advance(by: .seconds(1))
        await second?.value
        await store.expect { $0.lists.completeCompleting() }?.value
        await store.dismount()
        // A tap followed by a quit: the stored value still says completing, and the next mount finishes it.
        @Dependency(\.defaultDatabase) var database
        var stored = try #require(try await database.read { db in try Lists.load(db) })
        stored.toggle(doctor)
        try await database.write { [stored] db in try Lists.persist(stored, in: db) }
        let revived = await withDependencies { $0.continuousClock = clock } operation: {
            await TestStoreActor(initialState: Lists.Feature.State(lists: stored)) { Lists.Feature() }
        }
        await clock.advance(by: .seconds(5))
        await revived.expect { $0.lists.completeCompleting() }?.value
        await revived.dismount()
        #expect(try await database.read { db in try Lists.load(db) }?.reminder(doctor)?.status == .completed)
    }

    @Test func `a tap on the empty part of a list starts a row or ends editing, and leaving the detail commits`() async throws {
        let store = await makeStore()
        let personal = await store.state.lists.orderedLists[0].id
        await store.send(.backgroundTapped)?.value
        await store.send(.listTapped(personal)) { $0.lists.detail = .list(personal) }?.value
        let row = Reminder.ID(UUID(0))
        await store.send(.backgroundTapped) { $0.lists.startNewReminder(in: personal, id: row) }?.value
        await store.modify { $0.lists[draft: row].title = "Bread" } changes: { $0.lists[draft: row].title = "Bread" }?.value
        await store.send(.backgroundTapped) { $0.lists.endEditing() }?.value
        await store.send(.reminderTapped(row)) { $0.lists.edit(row) }?.value
        await store.send(.statTapped(.today)) {
            $0.lists.detail = .today
            $0.lists.endEditing()
        }?.value
        #expect(await store.state.lists.reminder(row)?.title == "Bread")
        await store.dismount()
    }

    @Test func `details from a row ends editing and opens the sheet on the stored reminder`() async throws {
        let store = await makeStore()
        let lists = await store.state.lists
        let personal = lists.orderedLists[0].id
        let groceries = lists.reminders[0]
        await store.send(.listTapped(personal)) { $0.lists.detail = .list(personal) }?.value
        await store.send(.reminderTapped(groceries.id)) { $0.lists.edit(groceries.id) }?.value
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.lists.endEditing()
            $0.destination = .reminder(snap(Reminder.Feature.State(reminder: groceries, isNew: false)))
        }?.value
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        await store.dismount()
    }

    @Test func `deleting the last list leaves a default one and closes its detail`() async throws {
        let store = await makeStore()
        let ids = await store.state.lists.orderedLists.map(\.id)
        await store.send(.listTapped(ids[0])) { $0.lists.detail = .list(ids[0]) }?.value
        await store.send(.listDeleted(ids[0])) { $0.lists.delete(list: ids[0]) }?.value
        await store.send(.listDeleted(ids[1])) { $0.lists.delete(list: ids[1]) }?.value
        await store.send(.listDeleted(ids[2])) {
            $0.lists.delete(list: ids[2])
            $0.lists.upsert(.default(id: Reminder.List.ID(UUID(0))))
        }?.value
        let lists = await store.state.lists
        #expect(lists.orderedLists.map(\.title) == ["Personal"] && lists.reminders.isEmpty && lists.detail == nil)
        await store.dismount()
    }

    @Test func `the list form edits a list and the reminder form's tag intents change every reminder`() async throws {
        let store = await makeStore()
        let lists = await store.state.lists
        let family = lists.orderedLists[1]
        await store.send(.listDetailsButtonTapped(family.id)) {
            $0.destination = .list(snap(Reminder.List.Feature.State(list: family, isNew: false)))
        }?.value
        await store.modify {
            if case var .list(form) = $0.destination { form.list.title = "Home"; $0.destination = .list(form) }
        } changes: {
            if case var .list(form) = $0.destination { form.list.title = "Home"; $0.destination = .list(form) }
        }?.value
        await store.send(.destination(.list(.saveButtonTapped))) {
            var renamed = family
            renamed.title = "Home"
            $0.lists.upsert(renamed)
            $0.destination = nil
        }?.value
        let groceries = lists.reminders[0]
        await store.send(.reminderDetailsButtonTapped(groceries.id)) {
            $0.lists.endEditing()
            $0.destination = .reminder(snap(Reminder.Feature.State(reminder: groceries, isNew: false)))
        }?.value
        await store.send(.destination(.reminder(.tagRenamed("someday", "later")))) {
            $0.lists.rename(tag: "someday", to: "later")
            if case var .reminder(form) = $0.destination {
                form.reminder.tags.remove("someday")
                form.reminder.tags.insert("later")
                $0.destination = .reminder(form)
            }
        }?.value
        await store.send(.destination(.reminder(.tagDeleted("optional")))) {
            $0.lists.delete(tag: "optional")
            if case var .reminder(form) = $0.destination { form.reminder.tags.remove("optional"); $0.destination = .reminder(form) }
        }?.value
        await store.send(.destination(.reminder(.cancelButtonTapped))) { $0.destination = nil }?.value
        let after = await store.state.lists
        #expect(after.list(family.id)?.title == "Home")
        #expect(after.reminders.filter { $0.tags.contains("later") }.count == 2 && !after.tags.contains(Tag(title: "optional")))
        await store.dismount()
    }

    @Test func `search tokens, the completed toggle, clearing, and the seed`() async throws {
        let store = await makeStore()
        await store.send(.searchTagTapped("car")) { $0.search.add(tag: "car") }?.value
        await store.send(.searchCompletedButtonTapped) { $0.search.showCompleted = true }?.value
        await store.send(.deleteCompletedButtonTapped(olderThanMonths: nil)) {
            $0.lists.deleteCompleted(matching: $0.search, olderThanMonths: nil, at: now, calendar: calendar)
        }?.value
        #expect(await store.state.lists.reminders.count == 10)
        // Leaving search puts the completed toggle back.
        await store.modify { $0.search.tokens = [] } changes: {
            $0.search.tokens = []
            $0.search.showCompleted = false
        }?.value
        await store.send(.tagDeleted("car")) { $0.lists.delete(tag: "car") }?.value
        await store.send(.seedButtonTapped) { $0.lists = Lists.sample(at: now) }?.value
        await store.dismount()
    }

    @Test func `a form with a blank title does not save`() async throws {
        let store = await makeStore()
        let list = Reminder.List(id: Reminder.List.ID(UUID(0)))
        await store.send(.addListButtonTapped) {
            $0.destination = .list(snap(Reminder.List.Feature.State(list: list, isNew: true)))
        }?.value
        await store.send(.destination(.list(.saveButtonTapped)))?.value
        #expect(await store.state.lists.lists.count == 3)
        await store.send(.destination(.list(.cancelButtonTapped))) { $0.destination = nil }?.value
        await store.dismount()
    }
}
