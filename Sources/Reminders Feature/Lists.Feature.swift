public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Reminders
import Reminders_SQLiteData
import SQLiteData
public import Tagged

/// The Reminders feature: state is the lists value plus the search and the two
/// form drafts; updates delegate to the domain; effects load and persist through
/// `Reminders SQLiteData` and run the completion grace timer.
extension Lists {
    /// The TCA26 feature for this domain. `State.Feature` names the feature type
    /// explicitly; the macro would otherwise synthesize `typealias Feature = Feature`.
    /// `State`, `Action`, and `body` stay in the type body because the macro reads them.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Lists.Feature

            public var lists: Lists
            public var search = Lists.Search()
            /// The reminder being created or edited in the form sheet.
            public var reminder: Reminder?
            /// The list being created or edited in the form sheet.
            public var list: Reminder.List?

            public init(lists: Lists = .sample) {
                self.lists = lists
            }
        }

        public enum Action {
            case addListButtonTapped
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case listDeleted(Reminder.List.ID)
            case listDetailsButtonTapped(Reminder.List.ID)
            case listFormCancelled
            case listFormSaved
            case listTapped(Reminder.List.ID)
            case listsMoved(IndexSet, Int)
            case newReminderButtonTapped
            case orderingSelected(Lists.Ordering)
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case reminderFlagButtonTapped(Reminder.ID)
            case reminderFormCancelled
            case reminderFormSaved
            case remindersMoved(IndexSet, Int)
            case searchCompletedButtonTapped
            case searchTagTapped(Tag.ID)
            case seedButtonTapped
            case showCompletedButtonTapped
            case statTapped(Lists.Detail)
            case tagAdded(String)
            case tagDeleted(Tag.ID)
            case tagRenamed(Tag.ID, String)
            case tagTapped(Tag.ID)
        }

        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            Update { state, action in
                switch action {
                case .addListButtonTapped:
                    state.list = Reminder.List(id: Reminder.List.ID(uuid()))
                case let .deleteCompletedButtonTapped(months):
                    state.lists.deleteCompleted(matching: state.search, olderThanMonths: months, at: now)
                case let .listDeleted(id):
                    state.lists.delete(list: id)
                    if state.lists.isEmpty { state.lists.upsert(.default(id: Reminder.List.ID(uuid()))) }
                case let .listDetailsButtonTapped(id):
                    state.list = state.lists.list(id)
                case .listFormCancelled:
                    state.list = nil
                case .listFormSaved:
                    if let list = state.list { state.lists.upsert(list) }
                    state.list = nil
                case let .listTapped(id):
                    state.lists.detail = .list(id)
                case let .listsMoved(source, destination):
                    state.lists.move(lists: source, to: destination)
                case .newReminderButtonTapped:
                    let list = state.lists.detail.flatMap { detail -> Reminder.List.ID? in
                        if case let .list(id) = detail { id } else { nil }
                    }
                    guard let list = list ?? state.lists.orderedLists.first?.id else { return }
                    state.reminder = Reminder(id: Reminder.ID(uuid()), list: list)
                case let .orderingSelected(ordering):
                    if let detail = state.lists.detail { state.lists.set(ordering: ordering, for: detail) }
                case let .reminderCompleteButtonTapped(id):
                    state.lists.toggle(id)
                case let .reminderDeleted(id):
                    state.lists.delete(reminder: id)
                case let .reminderDetailsButtonTapped(id):
                    state.reminder = state.lists.reminder(id)
                case let .reminderFlagButtonTapped(id):
                    state.lists.flag(id)
                case .reminderFormCancelled:
                    state.reminder = nil
                case .reminderFormSaved:
                    if let reminder = state.reminder { state.lists.upsert(reminder) }
                    state.reminder = nil
                case let .remindersMoved(source, destination):
                    if let detail = state.lists.detail { state.lists.move(reminders: source, to: destination, in: detail, at: now) }
                case .searchCompletedButtonTapped:
                    state.search.showCompleted.toggle()
                case let .searchTagTapped(tag):
                    state.search.add(tag: tag)
                case .seedButtonTapped:
                    state.lists = Lists.sample(at: now)
                case .showCompletedButtonTapped:
                    if let detail = state.lists.detail { state.lists.toggleShowCompleted(for: detail) }
                case let .statTapped(detail):
                    state.lists.detail = detail
                case let .tagAdded(title):
                    state.lists.add(tag: title)
                    state.reminder?.tags.insert(Tag.ID(title))
                case let .tagDeleted(id):
                    state.lists.delete(tag: id)
                    state.reminder?.tags.remove(id)
                case let .tagRenamed(id, title):
                    state.lists.rename(tag: id, to: title)
                    if state.reminder?.tags.remove(id) != nil { state.reminder?.tags.insert(Tag.ID(title)) }
                case let .tagTapped(tag):
                    state.lists.detail = .tags([tag])
                }
            }
            .onMount { _ in
                store.addTask {
                    if let stored = try await database.read({ db in try Lists.load(db) }) {
                        try store.modify { $0.lists = stored }
                    } else {
                        let sample = Lists.sample(at: now)
                        try store.modify { $0.lists = sample }
                        try await database.write { db in try Lists.seed(sample, in: db) }
                    }
                }
            }
            .onChange(of: store.lists) { _, current, _ in
                store.addTask {
                    try await database.write { db in try Lists.persist(current, in: db) }
                }
            }
            .onChange(of: store.lists.completing) { _, completing, _ in
                guard !completing.isEmpty else { return }
                store.addTask {
                    try await clock.sleep(for: .seconds(5))
                    try store.modify { $0.lists.completeCompleting() }
                }
            }
            .onChange(of: store.search.text) { _, _, state in
                state.search.commitText()
                if !state.search.isActive { state.search.showCompleted = false }
            }
        }
    }
}
