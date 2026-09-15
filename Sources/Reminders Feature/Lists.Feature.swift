public import ComposableArchitecture2
public import Dependencies
public import Foundation
import IssueReporting
public import Reminders
import Reminders_SQLiteData
import SQLiteData
public import Tagged

/// The Reminders feature: state is the lists value, the search, and the presented
/// form (`Destination`); updates delegate to the domain; the mount loads the stored
/// lists synchronously through `Reminders SQLiteData`, and effects seed, persist,
/// and run the completion grace timer.
extension Lists {
    /// The TCA26 feature for this domain. `State.Feature` names the feature type
    /// explicitly; the macro would otherwise synthesize `typealias Feature = Feature`.
    /// `State`, `Action`, and `body` stay in the type body because the macro reads them.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Lists.Feature

            public var lists: Lists
            public var search = Lists.Search()
            /// The form sheet being shown, if any.
            public var destination: Destination.State?

            public init(lists: Lists = .sample) {
                self.lists = lists
            }
        }

        public enum Action {
            case addListButtonTapped
            case backgroundTapped
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case doneButtonTapped
            case destination(Destination.Action)
            case listDeleted(Reminder.List.ID)
            case listDetailsButtonTapped(Reminder.List.ID)
            case listTapped(Reminder.List.ID)
            case listsMoved(IndexSet, Int)
            case newReminderButtonTapped
            case orderingSelected(Lists.Ordering)
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case reminderTapped(Reminder.ID)
            case remindersMoved(IndexSet, Int)
            case searchCompletedButtonTapped
            case searchSubmitted
            case searchTagTapped(Tag.ID)
            case seedButtonTapped
            case showCompletedButtonTapped
            case statTapped(Lists.Detail)
            case tagDeleted(Tag.ID)
            case tagTapped(Tag.ID)
            case titleSubmitted
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
                    state.destination = .list(Reminder.List.Feature.State(list: Reminder.List(id: Reminder.List.ID(uuid()))))
                // A tap on the empty part of a list ends editing, or starts a new row in an idle list.
                case .backgroundTapped:
                    if state.lists.editing != nil {
                        state.lists.endEditing()
                    } else if case let .list(list) = state.lists.detail {
                        state.lists.startNewReminder(in: list, id: Reminder.ID(uuid()))
                    }
                case .doneButtonTapped:
                    state.lists.endEditing()
                case let .deleteCompletedButtonTapped(months):
                    state.lists.deleteCompleted(matching: state.search, olderThanMonths: months, at: now)
                case .destination(.list(.cancelButtonTapped)), .destination(.reminder(.cancelButtonTapped)):
                    state.destination = nil
                // A blank name is no list and no reminder: the sheet stays up.
                case .destination(.list(.saveButtonTapped)):
                    guard case let .list(form) = state.destination, !form.list.isBlank else { break }
                    state.lists.upsert(form.list)
                    state.destination = nil
                case .destination(.reminder(.saveButtonTapped)):
                    guard case let .reminder(form) = state.destination, !form.reminder.isBlank else { break }
                    state.lists.upsert(form.reminder)
                    state.destination = nil
                // The lists own the tags; the draft follows what the lists accepted, so adding a
                // tag that exists in another case attaches the existing tag instead of a twin.
                case let .destination(.reminder(.tagAdded(title))):
                    state.lists.add(tag: title)
                    if case var .reminder(form) = state.destination, let tag = state.lists.tag(titled: title) {
                        form.reminder.tags.insert(tag.id)
                        state.destination = .reminder(form)
                    }
                case let .destination(.reminder(.tagDeleted(id))):
                    state.lists.delete(tag: id)
                    if case var .reminder(form) = state.destination {
                        form.reminder.tags.remove(id)
                        state.destination = .reminder(form)
                    }
                case let .destination(.reminder(.tagRenamed(id, title))):
                    state.lists.rename(tag: id, to: title)
                    if case var .reminder(form) = state.destination, form.reminder.tags.remove(id) != nil {
                        form.reminder.tags.insert(state.lists.tag(titled: title)?.id ?? id)
                        state.destination = .reminder(form)
                    }
                case let .listDeleted(id):
                    state.lists.delete(list: id)
                    if state.lists.isEmpty { state.lists.upsert(.default(id: Reminder.List.ID(uuid()))) }
                case let .listDetailsButtonTapped(id):
                    if let list = state.lists.list(id) { state.destination = .list(Reminder.List.Feature.State(list: list)) }
                case let .listTapped(id):
                    state.lists.detail = .list(id)
                case let .listsMoved(source, destination):
                    state.lists.move(lists: source, to: destination)
                // Inside a list the new reminder is a row edited in place; from the home it is the sheet.
                case .newReminderButtonTapped:
                    if case let .list(list) = state.lists.detail {
                        state.lists.startNewReminder(in: list, id: Reminder.ID(uuid()))
                    } else if let list = state.lists.orderedLists.first?.id {
                        state.destination = .reminder(Reminder.Feature.State(reminder: Reminder(id: Reminder.ID(uuid()), list: list)))
                    }
                case let .orderingSelected(ordering):
                    if let detail = state.lists.detail { state.lists.set(ordering: ordering, for: detail) }
                case let .reminderCompleteButtonTapped(id):
                    state.lists.toggle(id)
                case let .reminderDeleted(id):
                    state.lists.delete(reminder: id)
                case let .reminderDetailsButtonTapped(id):
                    state.lists.endEditing()
                    if let reminder = state.lists.reminder(id) { state.destination = .reminder(Reminder.Feature.State(reminder: reminder)) }
                case let .reminderTapped(id):
                    state.lists.edit(id)
                case let .remindersMoved(source, destination):
                    if let detail = state.lists.detail { state.lists.move(reminders: source, to: destination, in: detail, at: now) }
                case .searchCompletedButtonTapped:
                    state.search.showCompleted.toggle()
                case .searchSubmitted:
                    state.search.commitText()
                case let .searchTagTapped(tag):
                    state.search.add(tag: tag)
                case .seedButtonTapped:
                    state.lists = Lists.sample(at: now)
                case .showCompletedButtonTapped:
                    if let detail = state.lists.detail { state.lists.toggleShowCompleted(for: detail) }
                case let .statTapped(detail):
                    state.lists.detail = detail
                case let .tagDeleted(id):
                    state.lists.delete(tag: id)
                case let .tagTapped(tag):
                    state.lists.detail = .tags([tag])
                case .titleSubmitted:
                    state.lists.continueEditing(id: Reminder.ID(uuid()))
                }
            }
            .ifLet(\.destination, action: \.destination) {
                Destination.body
            }
            .onMount { state in
                let stored = withErrorReporting { try database.read { db in try Lists.load(db) } } ?? nil
                if let stored {
                    state.lists = stored
                } else {
                    let sample = Lists.sample(at: now)
                    state.lists = sample
                    store.addTask {
                        try await database.write { db in try Lists.seed(sample, in: db) }
                    }
                }
            }
            // Leaving the detail commits the row being edited, as the stock app does.
            .onChange(of: store.lists.detail) { _, _, state in
                state.lists.endEditing()
            }
            .onChange(of: store.lists) { _, current, _ in
                store.addTask {
                    try await database.write { db in try Lists.persist(current, in: db) }
                }
            }
            // Restarts on every change, so the latest tap gets the full period; `initial` revives a
            // grace period that was still running when the app last quit.
            .onChange(of: store.lists.completing, initial: true) { _, completing, _ in
                guard !completing.isEmpty else { return }
                store.addTask {
                    try await clock.sleep(for: .seconds(5))
                    try store.modify { $0.lists.completeCompleting() }
                }
            }
            .onChange(of: store.search.isActive) { _, active, state in
                if !active { state.search.showCompleted = false }
            }
        }
    }
}
