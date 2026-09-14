import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Reminder {
    /// The sheet that creates or edits a reminder, as iOS 27's: title and notes in one
    /// card, Date and Time as a coupled pair, then List and the pushed Details (or, when
    /// editing, the organisation rows inline). The draft is edited through the binding;
    /// save and cancel are the caller's. Done needs a title, and an edited draft asks
    /// before it is discarded.
    public struct Form: SwiftUI.View {
        @Binding private var reminder: Reminder
        private var isNew: Bool
        private var isDirty: Bool
        private var lists: [Reminder.List]
        private var tags: [Tag]
        private var now: Date
        private var addTag: (String) -> Void
        private var renameTag: (Tag.ID, String) -> Void
        private var deleteTag: (Tag.ID) -> Void
        private var save: () -> Void
        private var cancel: () -> Void
        @State private var tagsPresented = false
        @State private var discardPresented = false
        @State private var expanded: Expansion?
        @FocusState private var titleFocused: Bool

        public init(
            reminder: Binding<Reminder>,
            isNew: Bool = true,
            isDirty: Bool = false,
            lists: [Reminder.List],
            tags: [Tag],
            now: Date = Date(),
            addTag: @escaping (String) -> Void,
            renameTag: @escaping (Tag.ID, String) -> Void,
            deleteTag: @escaping (Tag.ID) -> Void,
            save: @escaping () -> Void,
            cancel: @escaping () -> Void
        ) {
            self._reminder = reminder
            self.isNew = isNew
            self.isDirty = isDirty
            self.lists = lists
            self.tags = tags
            self.now = now
            self.addTag = addTag
            self.renameTag = renameTag
            self.deleteTag = deleteTag
            self.save = save
            self.cancel = cancel
        }

        /// Which of the two pickers is open under its row; only one at a time.
        private enum Expansion { case date, time }
    }
}

extension Reminder.Form {
    public var body: some SwiftUI.View {
        SwiftUI.Form {
            Section {
                TextField("Title", text: $reminder.title, axis: .vertical)
                    .font(.title2)
                    .focused($titleFocused)
                    .listRowSeparator(.hidden)
                TextField("Notes", text: $reminder.notes, axis: .vertical)
                    .lineLimit(1...6)
            }
            Section("Date & Time") {
                Toggle(isOn: dateOn.animation()) {
                    row("Date", systemImage: "calendar", subtitle: reminder.dayDescription(at: now)) {
                        if reminder.due != nil { expanded = expanded == .date ? nil : .date }
                    }
                }
                if expanded == .date, let due = reminder.due {
                    DatePicker("Date", selection: $reminder.due[or: due], displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Toggle(isOn: timeOn.animation()) {
                    row("Time", systemImage: "clock", subtitle: reminder.timeDescription()) {
                        if reminder.hasTime { expanded = expanded == .time ? nil : .time }
                    }
                }
                if expanded == .time, reminder.hasTime, let due = reminder.due {
                    DatePicker("Time", selection: $reminder.due[or: due], displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            if isNew {
                Section("More Options") { listPicker }
                Section {
                    NavigationLink {
                        SwiftUI.Form { details }
                            .navigationTitle("Details")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Details", systemImage: "info.circle")
                    }
                }
            } else {
                Section("Organisation") { listPicker }
                Section { details }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    if isDirty { discardPresented = true } else { cancel() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: save)
                    .buttonStyle(.glassProminent)
                    .disabled(reminder.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .confirmationDialog(discardTitle, isPresented: $discardPresented, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive, action: cancel)
        }
        .onAppear { titleFocused = isNew }
    }

    /// The question the sheet asks before an edited draft is discarded.
    public var discardTitle: String {
        isNew ? "Are you sure you want to discard this new reminder?" : "Are you sure you want to discard your changes?"
    }

    /// A toggle label with the gray outline glyph and, once set, the blue subtitle; tapping
    /// the text opens the picker under the row.
    private func row(_ title: String, systemImage: String, subtitle: String?, tap: @escaping () -> Void) -> some SwiftUI.View {
        Button(action: tap) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle).font(.footnote).foregroundStyle(.tint)
                    }
                }
            } icon: {
                Image(systemName: systemImage).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var listPicker: some SwiftUI.View {
        Picker(selection: $reminder.list) {
            ForEach(lists) { list in
                Label { Text(list.title) } icon: { Reminder.List.Badge(color: list.color.swiftUI, size: 28) }.tag(list.id)
            }
        } label: {
            Label {
                Text("List")
            } icon: {
                Reminder.List.Badge(color: lists.first { $0.id == reminder.list }?.color.swiftUI ?? .blue, size: 28)
            }
        }
        .pickerStyle(.navigationLink)
    }

    @ViewBuilder private var details: some SwiftUI.View {
        Picker(selection: $reminder.priority) {
            Text("None").tag(Reminder.Priority?.none)
            Divider()
            Text("High").tag(Reminder.Priority.high)
            Text("Medium").tag(Reminder.Priority.medium)
            Text("Low").tag(Reminder.Priority.low)
        } label: {
            Label("Priority", systemImage: "exclamationmark").foregroundStyle(.primary, .secondary)
        }
        Button { tagsPresented = true } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    if !reminder.tags.isEmpty {
                        Text(reminder.sortedTags.map { "#\($0)" }.joined(separator: " ")).lineLimit(1).truncationMode(.tail)
                    }
                    Image(systemName: "chevron.forward").font(.footnote.weight(.semibold))
                }
            } label: {
                Label("Tags", systemImage: "number").foregroundStyle(.primary, .secondary)
            }
        }
        .foregroundStyle(.primary)
        .popover(isPresented: $tagsPresented) {
            NavigationStack {
                Tag.Picker(selection: $reminder.tags, tags: tags, add: addTag, rename: renameTag, delete: deleteTag)
            }
        }
        Toggle(isOn: $reminder.flagged) {
            Label("Flag", systemImage: "flag").foregroundStyle(.primary, .secondary)
        }
    }

    /// Date on sets today and opens the calendar; off drops the time as well.
    private var dateOn: Binding<Bool> {
        Binding(
            get: { reminder.due != nil },
            set: { on in
                reminder.set(due: on ? Calendar.current.startOfDay(for: now) : nil)
                expanded = on ? .date : nil
                titleFocused = false
            }
        )
    }

    /// Time on turns the date on too and opens the wheel; off closes it.
    private var timeOn: Binding<Bool> {
        Binding(
            get: { reminder.hasTime },
            set: { on in
                reminder.set(hasTime: on, at: now)
                expanded = on ? .time : nil
                titleFocused = false
            }
        )
    }
}

extension Optional {
    fileprivate subscript(or fallback: Wrapped) -> Wrapped {
        get { self ?? fallback }
        set { self = newValue }
    }
}
