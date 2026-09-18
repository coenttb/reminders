public import ComposableArchitecture2
public import Reminder
public import Reminders_Feature
public import SwiftUI
public import Tagged

extension Reminder.Editor {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminder.Editor.Feature>
        private var focus: FocusState<Reminder.ID?>.Binding

        public init(store: StoreOf<Reminder.Editor.Feature>, focus: FocusState<Reminder.ID?>.Binding) {
            self.store = store
            self.focus = focus
        }
    }
}

extension Reminder.Editor.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 12) {
            Button { store.send(.completeButtonTapped) } label: {
                Image(systemName: store.draft.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(store.draft.completed ? SwiftUI::Color.accentColor : SwiftUI::Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            TextField("New Reminder", text: $store.draft.title)
                .focused(focus, equals: store.state.id)
                .onSubmit { store.send(.titleSubmitted) }
        }
    }
}
