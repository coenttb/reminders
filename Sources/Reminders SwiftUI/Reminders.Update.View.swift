public import ComposableArchitecture2
import Interface_ComposableArchitecture
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Update {
    @View(Reminders.Update.self)
    public struct View: SwiftUI::View {

        public var body: some SwiftUI::View {
            HStack(spacing: 12) {
                Button { store.completed.toggle() } label: {
                    Image(systemName: store.completed ? "circle.inset.filled" : "circle")
                        .foregroundStyle(store.completed ? SwiftUI::Color.accentColor : SwiftUI::Color.secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(store.completed ? "Mark incomplete" : "Mark complete")
                .accessibilityValue(store.title)
                TextField("New Reminder", text: $store.title)
                    .textFieldStyle(.plain)
                    .focusOnPresentation()
                    .onSubmit { store.dismiss() }
            }
        }
    }
}
