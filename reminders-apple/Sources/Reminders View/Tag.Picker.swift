public import Organizing
public import Reminders
public import Reminders_SQL
import Standard_Library_Extensions
public import SwiftUI
public import Tagged

extension Tag<Reminder> {
    public struct Picker {
        @Binding private var selection: Set<Tag<Reminder>.ID>
        private var tags: [Tag<Reminder>.Record]
        private var add: (String) -> Void
        private var rename: (Tag<Reminder>.ID, String) -> Void
        private var delete: (Tag<Reminder>.ID) -> Void
        @State private var editing: Tag<Reminder>.ID?
        @State private var adding = false
        @State private var title = ""
        @Environment(\.dismiss) private var dismiss

        public init(
            selection: Binding<Set<Tag<Reminder>.ID>>,
            tags: [Tag<Reminder>.Record],
            add: @escaping (String) -> Void,
            rename: @escaping (Tag<Reminder>.ID, String) -> Void,
            delete: @escaping (Tag<Reminder>.ID) -> Void
        ) {
            self._selection = selection
            self.tags = tags
            self.add = add
            self.rename = rename
            self.delete = delete
        }
    }
}

extension Tag<Reminder>.Picker: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI.Form {
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
                        Button("Delete", role: .destructive) { delete(tag.id) }
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
            Button("Save") { add(title) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Edit tag", isPresented: $editing.isPresent) {
            TextField("Tag name", text: $title)
            Button("Save") { if let editing { rename(editing, title) } }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        .navigationTitle("Tags")
    }
}
