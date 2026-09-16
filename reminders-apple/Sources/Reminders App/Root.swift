import SwiftUI_Extensions
public import ComposableArchitecture2
import Dependencies
import Organizing
public import Reminders
import Reminders_Application
public import Reminders_Feature
import Reminders_View
import Standard_Library_Extensions
public import SwiftUI
import Tagged

/// The application composes the home, search, the pushed detail, and the two
/// form sheets from its store; navigation is feature state. The
/// chrome follows iOS 27 Reminders: no home title, glass pills top-trailing,
/// the search field and New Reminder in the bottom bar, sheets with glyph buttons.
public struct Root: View {
    @Bindable private var store: StoreOf<Reminder.Feature>
    @Dependency(\.date.now) private var now
    @Dependency(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @State private var editMode: EditMode = .inactive

    public init(store: StoreOf<Reminder.Feature>) {
        self.store = store
    }
}

extension Root {
    public var body: some View {
        NavigationStack {
            SwiftUI.List {
                if store.search.isActive {
                    Reminder.Search.View(
                        store.search,
                        results: store.results,
                        now: now,
                        calendar: calendar,
                        rows: .init(
                            complete: { store.send(.reminderCompleteButtonTapped($0)) },
                            delete: { store.send(.reminderDeleted($0)) },
                            details: { store.send(.reminderDetailsButtonTapped($0)) }
                        ),
                        addTag: { store.send(.searchTagTapped($0)) },
                        toggleCompleted: { store.send(.searchCompletedButtonTapped) },
                        deleteCompleted: { store.send(.deleteCompletedButtonTapped(olderThanMonths: $0)) }
                    )
                } else {
                    Reminder.Overview.View(
                        store.overview,
                        now: now,
                        calendar: calendar,
                        open: { store.send(.filterTapped($0)) },
                        details: { store.send(.listDetailsButtonTapped($0)) },
                        delete: { store.send(.listDeleted($0)) },
                        move: { store.send(.listsMoved($0, $1)) },
                        deleteTag: { store.send(.tagDeleted($0)) }
                    )
                }
            }
            .listStyle(.insetGrouped)
            // Search results sit on a plain white page, as stock draws them.
            .scrollContentBackground(store.search.isActive ? .hidden : .visible)
            .background(SwiftUI.Color(.systemBackground))
            .environment(\.editMode, $editMode)
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.overview)
            .onSubmit(of: .search) { store.send(.searchSubmitted) }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Seed data", systemImage: "leaf") { store.send(.seedButtonTapped) }
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addListButtonTapped) } label: { Organizing.List<Reminder>.AddGlyph() }
                        .accessibilityLabel("Add List")
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                // Stock: "Edit" as text, Done as the prominent checkmark (Evidence/Parity/edit-mode).
                ToolbarItem(placement: .topBarTrailing) {
                    if editMode.isEditing {
                        Button("Done", systemImage: "checkmark") { withAnimation { editMode = .inactive } }
                            .buttonStyle(.glassProminent)
                    } else {
                        Button("Edit") { withAnimation { editMode = .active } }
                    }
                }
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus") { store.send(.newReminderButtonTapped) }
                        .buttonStyle(.glassProminent)
                }
                .visibilityPriority(.high)
            }
            .navigationDestination(item: $store.filter) { filter in
                Detail(filter, store: store)
            }
        }
        // Search is declared on the stack, not on the list inside it, as in the iOS 26
        // samples: declared on the content, SwiftUI vends the field from a second
        // navigation item and cancelling evicts the list's rows behind the keyboard.
        // The field lives in the bottom bar and minimizes to a pill; the system
        // owns its keyboard attachment and, on iPhone Duo, its bar placement.
        .searchable(text: $store.search.text, tokens: $store.search.tokens) { token in
            switch token {
            case let .near(text): Text(text)
            case let .tag(tag): Text(Tag<Reminder>.hashtag(tag))
            }
        }
        .searchToolbarBehavior(.minimize)
        .observingDivision()
        .sheet(item: $store.scope(\.destination).reminder) { form in
            @Bindable var form = form
            NavigationStack {
                Reminder.Form(
                    reminder: $form.reminder,
                    isNew: form.isNew,
                    isDirty: form.isDirty,
                    failure: form.failure,
                    lists: store.overview.lists.map(\.list),
                    tags: store.overview.rankedTags,
                    now: now,
                    calendar: calendar,
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
            // Stock opens Details at the height of its content (624 of 874 pt on the
            // iPhone 17) and grows to full height on a drag; New Reminder is full height.
            .presentationDetents(form.isNew ? [.large] : [.fraction(0.715), .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(SwiftUI.Color(.systemGroupedBackground))
        }
        .sheet(item: $store.scope(\.destination).list) { form in
            @Bindable var form = form
            NavigationStack {
                Organizing.List<Reminder>.Form(list: $form.list, isNew: form.isNew, isDirty: form.isDirty, failure: form.failure, save: { form.send(.saveButtonTapped) }, cancel: { form.send(.cancelButtonTapped) })
                    .navigationTitle(form.isNew ? "New List" : "List Info")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
        }
        // Coming back to the foreground may be coming back on another day.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.appActivated) }
        }
        // Dismissing the alert clears the failure through the binding's key path.
        .alert("Something went wrong", isPresented: $store.failure.isPresent) {
            Button("OK") {}
        } message: {
            Text(store.failure ?? "")
        }
    }
}
