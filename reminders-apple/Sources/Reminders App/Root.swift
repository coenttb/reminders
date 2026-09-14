public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature
import Reminders_View
public import SwiftUI
import Tagged

/// The application composes the home, search, the pushed detail, and the two
/// form sheets from its store; navigation is data in the domain value.
public struct Root: View {
    @Bindable private var store: StoreOf<Lists.Feature>
    @Dependency(\.date.now) private var now

    public init(store: StoreOf<Lists.Feature>) {
        self.store = store
    }
}

extension Root {
    public var body: some View {
        NavigationStack {
            List {
                if store.search.isActive {
                    Lists.Search.View(
                        store.search,
                        lists: store.lists,
                        now: now,
                        addTag: { store.send(.searchTagTapped($0)) },
                        toggleCompleted: { store.send(.searchCompletedButtonTapped) },
                        deleteCompleted: { store.send(.deleteCompletedButtonTapped(olderThanMonths: $0)) },
                        complete: { store.send(.reminderCompleteButtonTapped($0)) },
                        flag: { store.send(.reminderFlagButtonTapped($0)) },
                        delete: { store.send(.reminderDeleted($0)) },
                        details: { store.send(.reminderDetailsButtonTapped($0)) }
                    )
                } else {
                    Lists.View(
                        lists: store.lists,
                        now: now,
                        open: { store.send(.statTapped($0)) },
                        details: { store.send(.listDetailsButtonTapped($0)) },
                        delete: { store.send(.listDeleted($0)) },
                        move: { store.send(.listsMoved($0, $1)) },
                        deleteTag: { store.send(.tagDeleted($0)) }
                    )
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $store.search.text, tokens: $store.search.tokens) { token in
                switch token {
                case let .near(text): Text(text)
                case let .tag(tag): Text("#\(tag)")
                }
            }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("Seed data", systemImage: "leaf") { store.send(.seedButtonTapped) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button { store.send(.newReminderButtonTapped) } label: {
                            Label("New Reminder", systemImage: "plus.circle.fill").bold().font(.title3)
                        }
                        Spacer()
                        Button("Add List") { store.send(.addListButtonTapped) }.font(.title3)
                    }
                }
            }
            .navigationDestination(item: $store.lists.detail) { detail in
                Lists.Detail.View(
                    detail,
                    lists: store.lists,
                    now: now,
                    complete: { store.send(.reminderCompleteButtonTapped($0)) },
                    flag: { store.send(.reminderFlagButtonTapped($0)) },
                    delete: { store.send(.reminderDeleted($0)) },
                    details: { store.send(.reminderDetailsButtonTapped($0)) },
                    move: { store.send(.remindersMoved($0, $1)) },
                    order: { store.send(.orderingSelected($0)) },
                    toggleCompleted: { store.send(.showCompletedButtonTapped) },
                    newReminder: { store.send(.newReminderButtonTapped) }
                )
            }
        }
        .sheet(item: $store.reminder) { reminder in
            if let draft = Binding($store.reminder) {
                NavigationStack {
                    Reminder.Form(
                        reminder: draft,
                        lists: store.lists.orderedLists,
                        tags: store.lists.rankedTags,
                        addTag: { store.send(.tagAdded($0)) },
                        renameTag: { store.send(.tagRenamed($0, $1)) },
                        deleteTag: { store.send(.tagDeleted($0)) },
                        save: { store.send(.reminderFormSaved) },
                        cancel: { store.send(.reminderFormCancelled) }
                    )
                    .navigationTitle(store.lists.reminder(reminder.id) == nil ? "New Reminder" : "Details")
                }
            }
        }
        .sheet(item: $store.list) { list in
            if let draft = Binding($store.list) {
                NavigationStack {
                    Reminder.List.Form(list: draft, save: { store.send(.listFormSaved) }, cancel: { store.send(.listFormCancelled) })
                        .navigationTitle(store.lists.list(list.id) == nil ? "New List" : "Edit List")
                }
                .presentationDetents([.medium])
            }
        }
    }
}
