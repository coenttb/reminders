public import Models
public import Reminder
public import Reminders_Interface
public import Reminders_SQL
import Standard_Library_Extensions
public import SwiftUI
public import Tagged

extension Tag<Reminder>.Picker {
    public struct SwiftUI {
        @Binding private var selection: Set<Tag<Reminder>.ID>
        private var tags: [Tag<Reminder>.Record]
        private var picker: Tag<Reminder>.Picker
        @State private var editing: Tag<Reminder>.ID?
        @State private var adding = false
        @State private var title = ""
        @Environment(\.dismiss) private var dismiss

        public init(selection: Binding<Set<Tag<Reminder>.ID>>, tags: [Tag<Reminder>.Record], picker: Tag<Reminder>.Picker) {
            self._selection = selection
            self.tags = tags
            self.picker = picker
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
                        selection.toggle(tag.id)
                    } label: {
                        HStack {
                            Image(systemName: selection.contains(tag.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(.blue)
                            Text(Tag<Reminder>.hashtag(tag.id)).foregroundStyle(.primary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { picker.actions.delete(tag.id) }
                        Button("Edit") {
                            title = tag.title
                            editing = tag.id
                        }
                    }
                }
            }
        }
        .alert("New tag", isPresented: $adding) {
            TextField("Tag name", text: $title)
            Button("Save") { picker.actions.add(title) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Edit tag", isPresented: $editing.isPresent) {
            TextField("Tag name", text: $title)
            Button("Save") { if let editing { picker.actions.rename(editing, title) } }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        .navigationTitle("Tags")
    }
}
