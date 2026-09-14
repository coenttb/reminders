import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Reminders
import Reminders_App
import Reminders_Feature
import SwiftUI
import Testing

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
})
struct `Lists root` {
    @Test func `constructs from a store and reads the domain through it`() {
        let store = Store(initialState: Lists.Feature.State()) { Lists.Feature() }
        _ = Root(store: store)
        #expect(store.lists.orderedLists.map(\.title) == ["Personal", "Family", "Business"])
        store.send(.statTapped(.today))
        #expect(store.lists.detail == .today)
    }
}
