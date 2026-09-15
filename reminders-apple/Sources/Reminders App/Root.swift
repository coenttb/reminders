import SwiftUI_Extensions
public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature
import Reminders_View
public import SwiftUI
import Tagged

/// The application composes the home, search, the pushed detail, and the two
/// form sheets from its store; navigation is data in the domain value. The
/// chrome follows iOS 27 Reminders: no home title, glass pills top-trailing,
/// the search field and New Reminder in the bottom bar, sheets with glyph buttons.
public struct Root: View {
    @Bindable private var store: StoreOf<Lists.Feature>
    @Dependency(\.date.now) private var now

    public init(store: StoreOf<Lists.Feature>) {
        self.store = store
    }
}

extension Root {
    /// What a search result row can ask: search rows open details rather than editing in place.
    private var rows: Reminder.Row.Actions {
        Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) }
        )
    }

    public var body: some View {
        NavigationStack {
            List {
                if store.search.isActive {
                    Lists.Search.View(
                        store.search,
                        lists: store.lists,
                        now: now,
                        rows: rows,
                        addTag: { store.send(.searchTagTapped($0)) },
                        toggleCompleted: { store.send(.searchCompletedButtonTapped) },
                        deleteCompleted: { store.send(.deleteCompletedButtonTapped(olderThanMonths: $0)) }
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
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.lists)
            .searchable(text: $store.search.text, tokens: $store.search.tokens) { token in
                switch token {
                case let .near(text): Text(text)
                case let .tag(tag): Text("#\(tag.rawValue)")
                }
            }
            // The field lives in the bottom bar and minimizes to a pill; the system
            // owns its keyboard attachment and, on iPhone Duo, its bar placement.
            .searchToolbarBehavior(.minimize)
            .onSubmit(of: .search) { store.send(.searchSubmitted) }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Seed data", systemImage: "leaf") { store.send(.seedButtonTapped) }
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add List", systemImage: "text.badge.plus") { store.send(.addListButtonTapped) }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus") { store.send(.newReminderButtonTapped) }
                        .buttonStyle(.glassProminent)
                }
                .visibilityPriority(.high)
            }
            .navigationDestination(item: $store.lists.detail) { detail in
                Detail(detail, store: store)
            }
        }
        .observingDivision()
        .sheet(item: $store.scope(\.destination).reminder) { form in
            @Bindable var form = form
            NavigationStack {
                Reminder.Form(
                    reminder: $form.reminder,
                    isNew: form.isNew,
                    isDirty: form.isDirty,
                    lists: store.lists.orderedLists,
                    tags: store.lists.rankedTags,
                    now: now,
                    addTag: { form.send(.tagAdded($0)) },
                    renameTag: { form.send(.tagRenamed($0, $1)) },
                    deleteTag: { form.send(.tagDeleted($0)) },
                    save: { form.send(.saveButtonTapped) },
                    cancel: { form.send(.cancelButtonTapped) }
                )
                .navigationTitle(form.isNew ? "New Reminder" : "Details")
            }
            // An edited draft cannot be swiped away; the form's X asks before discarding.
            // SwiftUI has no hook on the drag itself (dismissalConfirmationDialog wraps
            // the dismiss action, not the gesture), and UIKit bridges are out.
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
        }
        .sheet(item: $store.scope(\.destination).list) { form in
            @Bindable var form = form
            NavigationStack {
                Reminder.List.Form(list: $form.list, isNew: form.isNew, isDirty: form.isDirty, save: { form.send(.saveButtonTapped) }, cancel: { form.send(.cancelButtonTapped) })
                    .navigationTitle(form.isNew ? "New List" : "List Info")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
        }
    }
}
