public import Reminders
public import SwiftUI

extension Reminder.List {
    /// The sheet that creates or edits a list: its name and color.
    public struct Form: SwiftUI.View {
        @Binding private var list: Reminder.List
        private var save: () -> Void
        private var cancel: () -> Void

        public init(list: Binding<Reminder.List>, save: @escaping () -> Void, cancel: @escaping () -> Void) {
            self._list = list
            self.save = save
            self.cancel = cancel
        }
    }
}

extension Reminder.List.Form {
    public var body: some SwiftUI.View {
        SwiftUI.Form {
            Section {
                TextField("List Name", text: $list.title)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.buttonBorder)
            }
            ColorPicker("Color", selection: $list.color.swiftUIBinding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem { Button("Save", action: save) }
            ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
        }
    }
}

extension Binding<Reminder.List.Color> {
    /// The domain color as a SwiftUI color binding for the picker.
    var swiftUIBinding: Binding<Color> {
        Binding<Color>(get: { wrappedValue.swiftUI }, set: { wrappedValue = Reminder.List.Color($0) })
    }
}
