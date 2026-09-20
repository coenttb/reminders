import Interface_ComposableArchitecture
public import Reminder
public import SwiftUI

extension Reminder {
    @View
    public struct View {
        @Binding private var draft: Reminder.Draft

        public var body: some SwiftUI::View {
            SwiftUI::Form {
                TextField("Title", text: $draft.title)
                Toggle("Completed", isOn: $draft.completed)
            }
        }
    }
}
