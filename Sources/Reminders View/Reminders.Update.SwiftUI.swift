public import ComposableArchitecture2
public import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
public import Tagged

extension Reminders.Update {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminders.Update.Feature>
        private var focus: FocusState<Reminder.ID?>.Binding

        public init(store: StoreOf<Reminders.Update.Feature>, focus: FocusState<Reminder.ID?>.Binding) {
            self.store = store
            self.focus = focus
        }
    }
}

extension Reminders.Update.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 12) {
            Button { store.send(.completeButtonTapped) } label: {
                Image(systemName: store.request.reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(store.request.reminder.completed ? SwiftUI::Color.accentColor : SwiftUI::Color.secondary)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            TextField("New Reminder", text: $store.request.reminder.title)
                .textFieldStyle(.plain)
                .focused(focus, equals: store.state.id)
                .onSubmit { store.send(.titleSubmitted) }
        }
    }
}
