import Interface_ComposableArchitecture
import Reminder
import SwiftUI

extension Reminder.View {
    @View
    struct Completion {
        private var completed: Bool
        private var title: String
        private var toggle: () -> Void

        var body: some SwiftUI::View {
            Button(action: toggle) {
                Image(systemName: completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(completed ? SwiftUI::Color.accentColor : SwiftUI::Color.secondary)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(completed ? "Mark incomplete" : "Mark complete")
            .accessibilityValue(title)
        }
    }
}
