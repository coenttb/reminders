import SwiftUI_Extensions
public import ComposableArchitecture2
import Dependencies
import Organizing
public import Reminders
import Reminders_Interface
import Standard_Library_Extensions
import Reminders_SQL
public import Reminders_Feature
#if DEBUG
import Reminders_Sample
#endif
import Reminders_View
public import SwiftUI
import Tagged

extension Reminders {
    public struct Screen {
        @Bindable private var store: StoreOf<Reminders.Feature>
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.scenePhase) private var scenePhase
        @State private var editMode: EditMode = .inactive

        public init(store: StoreOf<Reminders.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        NavigationStack {
            SwiftUI.List {
                if store.search.isActive {
                    Reminders.Search.View.SwiftUI(
                        contents: store.results,
                        view: Reminders.Search.View(
                            search: store.search,
                            now: now,
                            calendar: calendar,
                            actions: Reminders.Search.View.Actions(
                                rows: Reminders.Reminder.Row.Actions(
                                    complete: { store.send(.reminderCompleteButtonTapped($0)) },
                                    delete: { store.send(.reminderDeleted($0)) },
                                    details: { store.send(.reminderDetailsButtonTapped($0)) }
                                ),
                                addTag: { store.send(.searchTagTapped($0)) },
                                toggleCompleted: { store.send(.searchCompletedButtonTapped) },
                                endReached: { store.send(.resultsEndReached) },
                                deleteCompleted: { store.send(.deleteCompletedButtonTapped(olderThanMonths: $0)) }
                            )
                        )
                    )
                } else {
                    Reminders.Overview.View.SwiftUI(
                        contents: store.overview,
                        view: Reminders.Overview.View(
                            now: now,
                            calendar: calendar,
                            actions: Reminders.Overview.View.Actions(
                                open: { store.send(.filterTapped($0)) },
                                details: { store.send(.listDetailsButtonTapped($0)) },
                                delete: { store.send(.listDeleted($0)) },
                                move: { store.send(.listsMoved($0, $1)) },
                                deleteTag: { store.send(.tagDeleted($0)) }
                            )
                        )
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(store.search.isActive ? .hidden : .visible)
            .background(SwiftUI.Color(.systemBackground))
            .environment(\.editMode, $editMode)
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.overview)
            .onSubmit(of: .search) { store.send(.searchSubmitted) }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Reminders.Sample.Menu(store: store)
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addListButtonTapped) } label: { Organizing.List<Reminder>.AddGlyph() }
                        .accessibilityLabel("Add List")
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
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
                Reminders.Filter.Screen(filter, store: store)
            }
        }
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
                Reminders.Reminder.Form.SwiftUI(
                    draft: $form.draft,
                    tags: $form.tags,
                    lists: store.overview.lists.map(\.list),
                    available: store.overview.rankedTags,
                    form: Reminders.Reminder.Form(
                        isNew: form.isNew,
                        isDirty: form.isDirty,
                        failure: form.failure,
                        now: now,
                        calendar: calendar,
                        actions: Reminders.Reminder.Form.Actions(
                            save: { form.send(.saveButtonTapped) },
                            cancel: { form.send(.cancelButtonTapped) },
                            tags: Tag<Reminder>.Picker.Actions(
                                add: { form.send(.tagAdded($0)) },
                                rename: { form.send(.tagRenamed($0, $1)) },
                                delete: { form.send(.tagDeleted($0)) }
                            )
                        )
                    )
                )
                .navigationTitle(form.isNew ? "New Reminder" : "Details")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents(form.isNew ? [.large] : [.fraction(0.715), .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(SwiftUI.Color(.systemGroupedBackground))
        }
        .sheet(item: $store.scope(\.destination).list) { form in
            @Bindable var form = form
            NavigationStack {
                Organizing.List<Reminder>.Form.SwiftUI(
                    draft: $form.draft,
                    form: Organizing.List<Reminder>.Form(
                        isNew: form.isNew,
                        isDirty: form.isDirty,
                        failure: form.failure,
                        actions: Organizing.List<Reminder>.Form.Actions(save: { form.send(.saveButtonTapped) }, cancel: { form.send(.cancelButtonTapped) })
                    )
                )
                .navigationTitle(form.isNew ? "New List" : "List Info")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.appActivated) }
        }
        .alert("Something went wrong", isPresented: $store.failure.isPresent) {
            Button("OK") {}
        } message: {
            Text(store.failure ?? "")
        }
    }
}
