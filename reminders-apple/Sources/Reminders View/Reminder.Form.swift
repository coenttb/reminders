import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Reminder {
    /// The sheet that creates or edits a reminder. The draft is edited through the
    /// binding; tags are chosen in a popover; save and cancel are the caller's.
    public struct Form: SwiftUI.View {
        @Binding private var reminder: Reminder
        private var lists: [Reminder.List]
        private var tags: [Tag]
        private var addTag: (String) -> Void
        private var renameTag: (Tag.ID, String) -> Void
        private var deleteTag: (Tag.ID) -> Void
        private var save: () -> Void
        private var cancel: () -> Void
        @State private var tagsPresented = false

        public init(
            reminder: Binding<Reminder>,
            lists: [Reminder.List],
            tags: [Tag],
            addTag: @escaping (String) -> Void,
            renameTag: @escaping (Tag.ID, String) -> Void,
            deleteTag: @escaping (Tag.ID) -> Void,
            save: @escaping () -> Void,
            cancel: @escaping () -> Void
        ) {
            self._reminder = reminder
            self.lists = lists
            self.tags = tags
            self.addTag = addTag
            self.renameTag = renameTag
            self.deleteTag = deleteTag
            self.save = save
            self.cancel = cancel
        }
    }
}

extension Reminder.Form {
    public var body: some SwiftUI.View {
        SwiftUI.Form {
            TextField("Title", text: $reminder.title)
            ZStack {
                if reminder.notes.isEmpty {
                    TextEditor(text: .constant("Notes")).foregroundStyle(.placeholder).accessibilityHidden(true)
                }
                TextEditor(text: $reminder.notes)
            }
            .lineLimit(4)
            .padding(.horizontal, -5)
            Section {
                Button { tagsPresented = true } label: {
                    HStack {
                        Image(systemName: "number.square.fill").font(.title).foregroundStyle(.gray)
                        Text("Tags").foregroundStyle(.primary)
                        Spacer()
                        if !reminder.tags.isEmpty {
                            Text(reminder.sortedTags.map { "#\($0)" }.joined(separator: " "))
                                .lineLimit(1).truncationMode(.tail).font(.callout).foregroundStyle(.gray)
                        }
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .popover(isPresented: $tagsPresented) {
                NavigationStack {
                    Tag.Picker(selection: $reminder.tags, tags: tags, add: addTag, rename: renameTag, delete: deleteTag)
                }
            }
            Section {
                Toggle(isOn: $reminder.hasDue.animation()) {
                    HStack {
                        Image(systemName: "calendar.circle.fill").font(.title).foregroundStyle(.red)
                        Text("Date")
                    }
                }
                if let due = reminder.due {
                    DatePicker("", selection: $reminder.due[or: due], displayedComponents: [.date, .hourAndMinute])
                        .padding(.vertical, 2)
                }
            }
            Section {
                Toggle(isOn: $reminder.flagged) {
                    HStack {
                        Image(systemName: "flag.circle.fill").font(.title).foregroundStyle(.red)
                        Text("Flag")
                    }
                }
                Picker(selection: $reminder.priority) {
                    Text("None").tag(Reminder.Priority?.none)
                    Divider()
                    Text("High").tag(Reminder.Priority.high)
                    Text("Medium").tag(Reminder.Priority.medium)
                    Text("Low").tag(Reminder.Priority.low)
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill").font(.title).foregroundStyle(.red)
                        Text("Priority")
                    }
                }
                Picker(selection: $reminder.list) {
                    ForEach(lists) { list in Text(list.title).tag(list.id) }
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.circle.fill").font(.title)
                            .foregroundStyle(lists.first { $0.id == reminder.list }?.color.swiftUI ?? .blue)
                        Text("List")
                    }
                }
            }
        }
        .padding(.top, -28)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem { Button("Save", action: save) }
            ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
        }
    }
}

extension Reminder {
    fileprivate var hasDue: Bool {
        get { due != nil }
        set { due = newValue ? Date() : nil }
    }
}

extension Optional {
    fileprivate subscript(or fallback: Wrapped) -> Wrapped {
        get { self ?? fallback }
        set { self = newValue }
    }
}
