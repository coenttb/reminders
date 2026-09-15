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
