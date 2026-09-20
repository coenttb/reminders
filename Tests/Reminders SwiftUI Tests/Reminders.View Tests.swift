import Optic
import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import List
import Operation
import Reminder
import Reminders
import Reminders_Dependency
import Reminders_SwiftUI
import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite
import Testing
import SwiftUI

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
struct `Reminders root` {
    @Dependency(\.reminders) var reminders

    @Test func `the screen observes the database through its store`() async throws {
        let store = Store(initialState: Reminders.State()) { reminders }
        _ = Reminders.View(store: store)
        while store.read.lists == nil { await Task.yield() }
        #expect(store.read.lists?.map(\.list.title) == ["Personal", "Family"])
    }

    @Test func `scoped list sending closes the matching nested page`() async throws {
        let personal = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)).lists[0].id
        let store = Store(initialState: Reminders.State()) { reminders }
        store.read.page = .init(.list(personal))
        store.lists.delete(personal)
        #expect(store.state.read.page == nil)
        try await store.lists.writes()
        while store.read.lists?.map(\.list.title) != ["Family"] { await Task.yield() }
        #expect(store.writes.taskError == nil)
    }

    @Test func `nested create presentation sends its request and dismisses on success`() async throws {
        let store = Store(initialState: Reminders.State()) { reminders }
        store.lists.create = .init(List<Reminder>.Draft())
        let form = try #require(store.lists.scope(\.create))
        form.title = "Work"
        let sending = form.sending
        form.send()
        try await sending()
        #expect(store.state.lists.create == nil)
        while store.read.lists?.contains(where: { $0.list.title == "Work" }) != true { await Task.yield() }
    }

    @Test func `derived navigation bindings share canonical nested presentation state`() async throws {
        let personal = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)).lists[0].id
        let store = Store(initialState: Reminders.State()) { reminders }
        @ViewStore<Reminders> var viewStore = store
        let page: Binding<StoreOf<Reminders.Read.Page>?> = $viewStore.read.page
        let create: Binding<StoreOf<Reminders.Lists.Create>?> = $viewStore.lists.create
        #expect(page.wrappedValue == nil)
        #expect(create.wrappedValue == nil)
        store.read.page = .init(.list(personal))
        #expect(page.wrappedValue?.list == personal)
        store.lists.create = .init(List<Reminder>.Draft())
        let form = try #require(create.wrappedValue)
        @ViewStore<Reminders.Lists.Create> var formStore = form
        $formStore.title.wrappedValue = "Travel"
        #expect(store.state.lists.create?.request.title == "Travel")
        create.wrappedValue = nil
        #expect(store.state.lists.create == nil)
        #expect(store.state.read.page != nil)
        page.wrappedValue = nil
        #expect(store.state.read.page == nil)
    }

}
