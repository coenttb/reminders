import SwiftUI_Extensions
public import ComposableArchitecture2
import Models
import Reminder
public import Reminders
import Standard_Library_Extensions
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
        @Environment(\.scenePhase) private var scenePhase
        @State private var editMode: EditMode = .inactive
        #if DEBUG
        @State private var sample: StoreOf<Reminders.Sample.Feature>
        #endif

        public init(store: StoreOf<Reminders.Feature>) {
            self.store = store
            #if DEBUG
            _sample = State(initialValue: Store(initialState: Reminders.Sample.Feature.State()) { Reminders.Sample.Feature(replaced: { store.send(.databaseReplaced) }) })
            #endif
        }
    }
}

extension Reminders.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        NavigationStack {
            SwiftUI.List {
                if store.search.field.isActive {
                    Reminders.Search.SwiftUI(store: store.scope(\.search), contents: store.results)
                } else {
                    Reminders.Read.SwiftUI(store: store.scope(\.overview))
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(store.search.field.isActive ? .hidden : .visible)
            .background(SwiftUI.Color(.systemBackground))
            .environment(\.editMode, $editMode)
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.overview.summary)
            .onSubmit(of: .search) { store.send(.search(.submitted)) }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Reminders.Sample.Menu(store: sample)
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addListButtonTapped) } label: { Models.List<Reminder>.AddGlyph() }
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
            .navigationDestination(item: $store.scope(\.listing)) { listing in
                Reminders.Filter.Screen(store: store, listing: listing)
            }
        }
        .searchable(text: $store.search.field.text, tokens: $store.search.field.tokens) { token in
            switch token {
            case let .near(text): Text(text)
            case let .tag(tag): Text(Tag<Reminder>.hashtag(tag))
            }
        }
        .searchToolbarBehavior(.minimize)
        .observingDivision()
        .sheet(item: $store.scope(\.destination).reminder) { form in
            NavigationStack {
                Reminder.Form.SwiftUI(store: form, lists: store.overview.summary.lists.map(\.list), available: store.overview.summary.rankedTags)
                    .navigationTitle(form.isNew ? "New Reminder" : "Details")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(SwiftUI.Color(.systemGroupedBackground))
        }
        .sheet(item: $store.scope(\.destination).list) { form in
            NavigationStack {
                Models.List<Reminder>.Form.SwiftUI(store: form)
                    .navigationTitle(form.isNew ? "New List" : "List Info")
            }
            .interactiveDismissDisabled(form.isDirty)
            .presentationDetents([.large])
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.appActivated) }
            if phase == .background { store.send(.appBackgrounded) }
        }
        .alert("Something went wrong", isPresented: $store.failure.isPresent) {
            Button("OK") {}
        } message: {
            Text(store.failure ?? "")
        }
    }
}
