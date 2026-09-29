import ComposableArchitecture2
import Interface_ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import List
import Reminder
import Reminders
import Reminders_Dependency
import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite
import Reminders_SwiftUI
import SwiftUI
import RFC_4122
import Tagged
import Testing
import Time

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Time.Instant(secondsSinceUnixEpoch: 1_234_567_890)))
})
struct `Reminders views` {
    @Dependency(\.reminders) var reminders

    @Test func `a row is built from a value; the page from a store`() throws {
        let reminder = Reminder(
            id: Reminder.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000001")),
            list: List<Reminder>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000002")),
            title: "Milk", created: Time.Instant(secondsSinceUnixEpoch: 0)
        )
        _ = Reminder.View.Row(reminder: reminder, complete: {}, delete: {}, edit: {})
        let store = Store(initialState: Reminders.Read.Page.State(.all)) { reminders.read.page.interface(reminders) }
        _ = Reminders.Read.Page.View(store: store, title: "All")
    }
    @Test func `canonical presentations take their declared domain capabilities`() throws {
        let root = Store(initialState: Reminders.State()) { reminders }
        _ = Reminders.View(store: root)
        // Read renders the summary but also needs the root's list commands.
        _ = Reminders.Read.View(store: root)
        root.lists.create = .init(List<Reminder>.Draft())
        let create = try #require(root.lists.scope(\.create))
        _ = Reminders.Lists.Form(store: create, draft: \.draft, title: Text("New List"))
        root.lists.update = .init(List<Reminder>.default(id: List<Reminder>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000003"))))
        let update = try #require(root.lists.scope(\.update))
        _ = Reminders.Lists.Form(store: update, draft: \.list.draft, title: Text("List Info"))
        root.read.page = .init(.all)
        let page = try #require(root.read.scope(\.page))
        _ = Reminders.Read.Page.View(store: page, title: "All")
        let list = List<Reminder>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000004"))
        page.editing = .init(Reminder.Draft(list: list))
        @Bindable var editing = try #require(page.scope(\.editing))
        _ = Reminder.View(draft: $editing.draft)
        _ = Reminder.View.Row.Editor(draft: $editing.draft, submit: { editing.dismiss() })
        editing.title = "Shared draft"
        #expect(root.state.read.page?.editing?.title == "Shared draft")
        // Clear the draft before ending the test: the empty draft is discarded.
        editing.title = ""
        page.editing = nil
    }

}
