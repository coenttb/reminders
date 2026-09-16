import Foundation
public import Organizing
public import Reminders
import Reminders_Application
import Standard_Library_Extensions
public import SwiftUI
public import Tagged

extension Reminder {
    public struct Form: SwiftUI.View {
        @Binding private var reminder: Reminder
        private var isNew: Bool
        private var isDirty: Bool
        private var failure: String?
        private var lists: [Organizing.List<Reminder>]
        private var tags: [Tag<Reminder>]
        private var now: Date
        private var calendar: Calendar
        private var addTag: (String) -> Void
        private var renameTag: (Tag<Reminder>.ID, String) -> Void
        private var deleteTag: (Tag<Reminder>.ID) -> Void
        private var save: () -> Void
        private var cancel: () -> Void
        @State private var tagsPresented = false
        @State private var discardPresented = false
        @State private var expanded: Expansion?
        @FocusState private var titleFocused: Bool
        @FocusState private var notesFocused: Bool

        public init(
            reminder: Binding<Reminder>,
            isNew: Bool = true,
            isDirty: Bool = false,
            failure: String? = nil,
            lists: [Organizing.List<Reminder>],
            tags: [Tag<Reminder>],
            now: Date,
            calendar: Calendar,
            addTag: @escaping (String) -> Void,
            renameTag: @escaping (Tag<Reminder>.ID, String) -> Void,
            deleteTag: @escaping (Tag<Reminder>.ID) -> Void,
            save: @escaping () -> Void,
            cancel: @escaping () -> Void
        ) {
            self._reminder = reminder
            self.isNew = isNew
            self.isDirty = isDirty
            self.failure = failure
            self.lists = lists
            self.tags = tags
            self.now = now
            self.calendar = calendar
            self.addTag = addTag
            self.renameTag = renameTag
            self.deleteTag = deleteTag
            self.save = save
            self.cancel = cancel
        }

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
                    .focused($notesFocused)
            }
            .listSectionMargins(.top, 6)
            Section("Date & Time") {
                Toggle(isOn: $reminder.dueOn(now, calendar: calendar).animation()) {
                    row("Date", systemImage: "calendar", subtitle: reminder.due?.dayDescription(at: now, calendar: calendar)) {
                        if reminder.due != nil { expanded = expanded == .date ? nil : .date }
                    }
                }
                if expanded == .date, let due = reminder.due {
                    DatePicker("Date", selection: $reminder.date(or: due.date), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Toggle(isOn: $reminder.timeOn(now, calendar: calendar).animation()) {
                    row("Time", systemImage: "clock", subtitle: reminder.due?.timeDescription(calendar: calendar)) {
                        if reminder.due?.hasTime == true { expanded = expanded == .time ? nil : .time }
                    }
                }
                if expanded == .time, let due = reminder.due, due.hasTime {
                    DatePicker("Time", selection: $reminder.date(or: due.date), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            if reminder.due != nil {
                Section {
                    Picker(selection: $reminder.repeats) {
                        ForEach(Reminder.Repeat.allCases, id: \.self) { Text($0.title).tag($0) }
                    } label: {
                        Label("Repeat", systemImage: "repeat").foregroundStyle(.primary, .secondary)
                    }
                }
            }
            if let failure {
                Section { Text(failure).foregroundStyle(.red) } header: { Text("Not saved") }
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
                Section { priorityPicker }
                Section {
                    tagsRow
                    flagToggle
                }
                Section("Places & People") { locationPicker }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaBar(edge: .bottom) {
            if titleFocused || notesFocused { quickBar }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    if isDirty { discardPresented = true } else { cancel() }
                }
                .discardPrompt(discardTitle, isPresented: $discardPresented, discard: cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: save)
                    .buttonStyle(.glassProminent)
                    .disabled(reminder.isBlank)
            }
        }
        .onAppear { titleFocused = isNew }
        .onChange(of: reminder.due != nil) { _, on in
            expanded = on ? .date : nil
            titleFocused = false
        }
        .onChange(of: reminder.due?.hasTime == true) { _, on in
            expanded = on ? .time : nil
            titleFocused = false
        }
    }

    private var quickBar: some SwiftUI.View {
        HStack {
            Menu {
                ForEach(Reminder.Due.Preset.allCases, id: \.self) { preset in
                    let date = preset.date(at: now, calendar: calendar)
                    Button(preset.title, systemImage: "\(calendar.component(.day, from: date)).calendar") {
                        reminder.set(datePreset: preset, at: now, calendar: calendar)
                    }
                }
                Button("Custom", systemImage: "ellipsis") {
                    if reminder.due == nil { reminder.set(datePreset: .today, at: now, calendar: calendar) }
                    expanded = .date
                }
            } label: {
                Label("Date & Time", systemImage: "calendar.badge.clock")
            }
            Spacer()
            Menu {
                Button("None") { reminder.location = nil }
                ForEach(Reminder.Location.allCases, id: \.self) { location in
                    Button(location.title) { reminder.location = location }
                }
            } label: {
                Label("Location", systemImage: "location")
            }
            Spacer()
            Button("Flag", systemImage: reminder.flagged ? "flag.fill" : "flag") { reminder.flagged.toggle() }
                .disabled(reminder.isBlank)
            Spacer()
            Button("Photos", systemImage: "camera") {}
                .disabled(true)
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .foregroundStyle(.primary)
        .padding(.horizontal, 22)
        .frame(height: 50)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    public var discardTitle: String {
        isNew ? "Are you sure you want to discard this new reminder?" : "Are you sure you want to discard your changes?"
    }

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
        NavigationLink {
            SwiftUI.List(lists) { list in
                Button { reminder.list = list.id } label: {
                    HStack(spacing: 16) {
                        Organizing.List<Reminder>.Badge(color: SwiftUI.Color(list.color))
                        Text(list.title).foregroundStyle(.primary)
                        Spacer()
                        if list.id == reminder.list {
                            Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("List")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            LabeledContent {
                Text(lists.first(id: reminder.list)?.title ?? "")
            } label: {
                Label {
                    Text("List")
                } icon: {
                    Organizing.List<Reminder>.Badge(color: lists.first(id: reminder.list).map { SwiftUI.Color($0.color) } ?? .blue, size: 28)
                }
            }
        }
    }

    @ViewBuilder private var details: some SwiftUI.View {
        priorityPicker
        tagsRow
        flagToggle
        locationPicker
    }

    private var priorityPicker: some SwiftUI.View {
        Picker(selection: $reminder.priority) {
            Text("None").tag(Reminder.Priority?.none)
            Divider()
            ForEach(Reminder.Priority.allCases.reversed(), id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Priority", systemImage: "exclamationmark").foregroundStyle(.primary, .secondary)
        }
    }

    private var tagsRow: some SwiftUI.View {
        Button { tagsPresented = true } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    if !reminder.tags.isEmpty {
                        Text(reminder.tagLine).lineLimit(1).truncationMode(.tail)
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
                Tag<Reminder>.Picker(selection: $reminder.tags, tags: tags, add: addTag, rename: renameTag, delete: deleteTag)
            }
        }
    }

    private var flagToggle: some SwiftUI.View {
        Toggle(isOn: $reminder.flagged) {
            Label("Flag", systemImage: "flag").foregroundStyle(.primary, .secondary)
        }
    }

    private var locationPicker: some SwiftUI.View {
        Picker(selection: $reminder.location) {
            Text("None").tag(Reminder.Location?.none)
            Divider()
            ForEach(Reminder.Location.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Location", systemImage: "location").foregroundStyle(.primary, .secondary)
        }
    }
}
