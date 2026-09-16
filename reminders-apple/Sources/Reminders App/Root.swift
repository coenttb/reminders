import SwiftUI_Extensions
public import ComposableArchitecture2
import Dependencies
import Organizing
public import Reminders
import Reminders_Application
import Reminders_Sample
public import Reminders_Feature
import Reminders_View
import Standard_Library_Extensions
public import SwiftUI
import Tagged

public struct Root {
    @Bindable private var store: StoreOf<Reminder.Feature>
    @Dependency(\.date.now) private var now
    @Dependency(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @State private var editMode: EditMode = .inactive

    public init(store: StoreOf<Reminder.Feature>) {
        self.store = store
    }
}

extension Root: SwiftUI::View {
    public var body: some SwiftUI::View {
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
                        deleteCompleted: { store.send(.deleteCompletedButtonTapped(olderThanMonths: $0)) },
                        endReached: { store.send(.resultsEndReached) }
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
            .scrollContentBackground(store.search.isActive ? .hidden : .visible)
            .background(SwiftUI.Color(.systemBackground))
            .environment(\.editMode, $editMode)
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.overview)
            .onSubmit(of: .search) { store.send(.searchSubmitted) }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reference sample", systemImage: "leaf") { store.send(.seedButtonTapped) }
                        Section("Fixed seed") {
                            ForEach([Reminder.Sample.Scale.medium, .large, .extreme], id: \.self) { scale in
                                Button(scale.title) { store.send(.seedGenerated(scale, seed: 1)) }
                            }
                        }
                        Section("Random seed") {
                            ForEach([Reminder.Sample.Scale.medium, .large, .extreme], id: \.self) { scale in
                                Button(scale.title) { store.send(.seedGenerated(scale, seed: nil)) }
                            }
                        }
                        if let last = store.lastSeed {
                            Button("Replay \(last.description)", systemImage: "arrow.counterclockwise") {
                                store.send(.seedGenerated(last.scale, seed: last.value))
                            }
                        }
                        Divider()
                        Button("Delete everything", systemImage: "trash", role: .destructive) { store.send(.deleteEverythingButtonTapped) }
                    } label: {
                        if store.isSeeding {
                            ProgressView()
                        } else {
                            Label("Seed data", systemImage: "leaf")
                        }
                    }
                    .disabled(store.isSeeding)
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
                Detail(filter, store: store)
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
            .interactiveDismissDisabled(form.isDirty)
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
