public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Reminders_SQLite
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminders.Overview {
    // The front screen: `read(today:)` observed, with the intents that act on lists and tags as a whole.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Overview.Feature

            public var today: Date?
            @DebugSnapshotIgnored @Fetch public var summary = Reminders.Summary()

            public init(today: Date? = nil) {
                self.today = today
            }
        }

        public enum Action {
            case filterTapped(Reminders.Filter)
            case listDeleted(Models.List<Reminder>.ID)
            case listDetailsButtonTapped(Models.List<Reminder>.ID)
            case listTapped(Models.List<Reminder>.ID)
            case listsMoved(IndexSet, Int)
            case tagDeleted(Tag<Reminder>)
            case tagTapped(Tag<Reminder>)
        }

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .filterTapped, .listDeleted, .listDetailsButtonTapped, .listTapped, .tagTapped:
                    break
                case let .listsMoved(source, destination):
                    var ids = state.summary.lists.map(\.id)
                    ids.move(offsets: source, to: destination)
                    store.addTask {
                        try await store.attempt { try reminders.lists.reorder(ids) }
                    }
                case let .tagDeleted(tag):
                    store.addTask {
                        try await store.attempt {
                            try reminders.tags.delete(tag)
                            try store.post(key: Reminders.Feature.TagDeleted.self, value: tag)
                        }
                    }
                }
            }
            .onChange(of: store.today.map { Reminders.Read.Today.Request(today: $0) }, initial: true) { _, request, state in
                guard let request else { return }
                let summary = state.$summary
                store.addTask {
                    try await store.attempt { try await summary.load(request) }
                }
            }
        }
    }
}
