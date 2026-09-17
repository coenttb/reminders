public import ComposableArchitecture2
import Reminders
public import Reminders_Feature
public import Models
public import Reminder
import Standard_Library_Extensions
public import SwiftUI
import Tagged

extension Tag<Reminder> {
    public enum Picker {}
}

extension Tag<Reminder>.Picker {
    // Picks the tags of the reminder form's draft; the tag intents are the form's.
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminder.Form.Feature>
        private var tags: [Tag<Reminder>]
        @State private var editing: Tag<Reminder>?
        @State private var adding = false
        @State private var title = ""
        @Environment(\.dismiss) private var dismiss

        public init(store: StoreOf<Reminder.Form.Feature>, tags: [Tag<Reminder>]) {
            self.store = store
            self.tags = tags
        }
    }
}

extension Tag<Reminder>.Picker.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::Form {
            Section {
                Button("New tag") {
                    title = ""
                    adding = true
                }
            }
            Section {
                ForEach(tags) { tag in
                    Button {
                        store.send(.tagToggled(tag))
                    } label: {
                        HStack {
                            Image(systemName: store.draft.tags.contains(tag) ? "checkmark.circle.fill" : "circle").foregroundStyle(.blue)
                            Text(tag.hashtag).foregroundStyle(.primary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.send(.tagDeleted(tag)) }
                        Button("Edit") {
                            title = tag.rawValue
                            editing = tag
                        }
                    }
                }
            }
        }
        .alert("New tag", isPresented: $adding) {
            TextField("Tag name", text: $title)
            Button("Save") { store.send(.tagAdded(title)) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Edit tag", isPresented: $editing.isPresent) {
            TextField("Tag name", text: $title)
            Button("Save") { if let editing { store.send(.tagRenamed(editing, title)) } }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        .navigationTitle("Tags")
    }
}
