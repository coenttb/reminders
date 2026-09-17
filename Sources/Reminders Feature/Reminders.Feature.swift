public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Sharing
public import Tagged

extension Reminders {
    // The app: navigation between the screens, the sheets, the day, and what a relaunch restores.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Feature

            public var overview: Reminders.Read.Feature.State
            public var search: Reminders.Search.Feature.State
            public var listing: Reminders.Listing.Feature.State?
            public var destination: Destination.State?
            public var today: Date
            public var failure: String?

            @DebugSnapshotIgnored @Shared(.appStorage(Feature.filterKey)) public var filterKey: Reminders.Filter.Key? = nil
            @DebugSnapshotIgnored @Shared(.appStorage(Reminders.Listing.Feature.editingKey)) public var editingID: String? = nil

            // The initial state is the restored one: the open filter and the row being edited come back from app storage.
            public init() {
                @Dependency(\.calendar) var calendar
                @Dependency(\.date.now) var now
                @Dependency(\.reminders) var reminders
                @Dependency(\.uuid) var uuid
                @Shared(.appStorage(Feature.filterKey)) var filterKey: Reminders.Filter.Key?
                @Shared(.appStorage(Reminders.Listing.Feature.editingKey)) var editingID: String?
                let today = calendar.startOfDay(for: now)
                var listing: Reminders.Listing.Feature.State?
                var failure: String?
                // A list or tags that are gone since take the app back to the front screen.
                var known = false
                if let filter = filterKey.flatMap(Reminders.Filter.init(key:)) {
                    do {
                        let summary = try reminders.read(today: now)
                        known = switch filter {
                        case let .list(id): summary.lists.contains { $0.id == id }
                        case let .tags(tags): tags.allSatisfy { tag in summary.tags.contains { $0.tag == tag } }
                        default: true
                        }
                    } catch {
                        failure = error.localizedDescription
                    }
                }
                if !known { $filterKey.withLock { $0 = nil } }
                if known, let filter = filterKey.flatMap(Reminders.Filter.init(key:)) {
                    listing = Reminders.Listing.Feature.State(filter: filter, today: today)
                    if let stored = editingID.flatMap(UUID.init(uuidString:)) {
                        do {
                            listing?.editing = Reminder.Editor.Feature.State(try reminders.read(Reminder.ID(stored)), session: uuid())
                        } catch Reminders.Read.Error.notFound {
                        } catch {
                            failure = error.localizedDescription
                        }
                    }
                    $editingID.withLock { $0 = listing?.editing?.id.rawValue.uuidString }
                }
                self.today = today
                self.overview = Reminders.Read.Feature.State(today: today)
                self.search = Reminders.Search.Feature.State(today: today)
                self.listing = listing
                self.failure = failure
            }

            public var results: Reminders.Search.Contents {
                Reminders.Search.Contents(search.matches.map(search.shown), lists: overview.summary.lists, suggestions: search.suggestions)
            }
        }

        public enum Action {
            case addListButtonTapped
            case appActivated
            case appBackgrounded
            case databaseReplaced
            case destination(Destination.Action)
            case listing(Reminders.Listing.Feature.Action)
            case newReminderButtonTapped
            case overview(Reminders.Read.Feature.Action)
            case search(Reminders.Search.Feature.Action)
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    switch action {
                    case .addListButtonTapped:
                        state.destination = .list(Models.List<Reminder>.Form.Feature.State(draft: Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid())), original: nil))
                    case .appActivated:
                        state.today = calendar.startOfDay(for: now)
                    case .appBackgrounded:
                        let listing = state.listing != nil
                        store.addTask {
                            try store.send(.search(.graceEnded))
                            if listing { try store.send(.listing(.graceEnded)) }
                        }
                    case .databaseReplaced:
                        state.listing = nil
                    case .destination(.list(.cancelButtonTapped)), .destination(.reminder(.cancelButtonTapped)):
                        state.destination = nil
                    case .destination:
                        break
                    case .listing(.listDeleteButtonTapped):
                        if let id = state.listing?.list { delete(list: id) }
                    case .listing(.listInfoButtonTapped):
                        if let id = state.listing?.list { showDetails(of: id, &state) }
                    case .listing:
                        break
                    case .newReminderButtonTapped:
                        if let list = state.overview.summary.lists.first?.id {
                            state.destination = .reminder(Reminder.Form.Feature.State(draft: Reminder(id: Reminder.ID(uuid()), list: list, created: now), original: nil))
                        }
                    case let .overview(.filterTapped(filter)):
                        open(filter, &state)
                    case let .overview(.listDeleted(id)):
                        delete(list: id)
                    case let .overview(.listDetailsButtonTapped(id)):
                        showDetails(of: id, &state)
                    case let .overview(.listTapped(id)):
                        open(.list(id), &state)
                    case let .overview(.tagTapped(tag)):
                        open(.tags([tag]), &state)
                    case .overview, .search:
                        break
                    }
                }
                ComposableArchitecture2.Scope(\.overview) { Reminders.Read.Feature() }
                ComposableArchitecture2.Scope(\.search) { Reminders.Search.Feature() }
            }
            .ifLet(\.listing) {
                Reminders.Listing.Feature()
            }
            .ifLet(\.destination) {
                Destination.body
            }
            .onEvent(Failed.self) { reason, state in
                state.failure = reason
            }
            .onEvent(ReminderDetailsRequested.self) { reminder, state in
                state.destination = .reminder(Reminder.Form.Feature.State(draft: reminder, original: reminder))
            }
            .onEvent(TagDeleted.self) { tag, state in
                guard let listing = state.listing else { return }
                if let filter = listing.filter.removing(tag: tag) {
                    state.listing?.filter = filter
                } else {
                    state.listing = nil
                }
            }
            .onChange(of: store.today, initial: true) { _, today, state in
                state.overview.today = today
                state.search.today = today
                state.listing?.today = today
                guard let day = calendar.day(containing: today) else { return }
                store.addTask {
                    try await clock.sleep(for: .seconds(max(day.upperBound.timeIntervalSince(now), 0)))
                    try store.modify { $0.today = calendar.startOfDay(for: now) }
                }
            }
            .onChange(of: store.listing?.filter) { _, filter, state in
                state.$filterKey.withLock { $0 = filter.map(Reminders.Filter.Key.init) }
                if filter == nil { state.$editingID.withLock { $0 = nil } }
            }
        }
    }
}

extension Reminders.Feature {
    public static let filterKey = "remindersFilter"

    private func open(_ filter: Reminders.Filter, _ state: inout State) {
        state.listing = Reminders.Listing.Feature.State(filter: filter, today: state.today)
    }

    private func showDetails(of id: Models.List<Reminder>.ID, _ state: inout State) {
        if let list = state.overview.summary.list(id) {
            state.destination = .list(Models.List<Reminder>.Form.Feature.State(draft: list, original: list))
        }
    }

    private func delete(list id: Models.List<Reminder>.ID) {
        let replacement = Models.List<Reminder>.ID(uuid())
        store.addTask {
            try await store.attempt {
                try await reminders.lists.delete(id, replacement: replacement)
                try store.modify { if $0.listing?.list == id { $0.listing = nil } }
            }
        }
    }
}
