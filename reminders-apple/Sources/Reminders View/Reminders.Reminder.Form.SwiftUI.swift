public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
import Standard_Library_Extensions
public import SwiftUI
public import Tagged

extension Reminders.Reminder.Form {
    public struct SwiftUI {
        @Binding private var draft: Reminder.Record.Draft
        @Binding private var tags: Set<Tag<Reminder>.ID>
        private var lists: [Organizing.List<Reminder>.Record]
        private var available: [Tag<Reminder>.Record]
        private var form: Reminders.Reminder.Form
        @State private var tagsPresented = false
        @State private var discardPresented = false
        @State private var expanded: Expansion?
        @FocusState private var titleFocused: Bool
        @FocusState private var notesFocused: Bool

        public init(
            draft: Binding<Reminder.Record.Draft>,
            tags: Binding<Set<Tag<Reminder>.ID>>,
            lists: [Organizing.List<Reminder>.Record],
            available: [Tag<Reminder>.Record],
            form: Reminders.Reminder.Form
        ) {
            self._draft = draft
            self._tags = tags
            self.lists = lists
            self.available = available
            self.form = form
        }

        private enum Expansion { case date, time }
    }
}

extension Reminders.Reminder.Form.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let (now, calendar) = (form.now, form.calendar)
        SwiftUI::Form {
            Section {
                TextField("Title", text: $draft.title, axis: .vertical)
                    .font(.title2)
                    .focused($titleFocused)
                    .listRowSeparator(.hidden)
                TextField("Notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($notesFocused)
            }
            .listSectionMargins(.top, 6)
            Section("Date & Time") {
                Toggle(isOn: $draft.dueOn(now, calendar: calendar).animation()) {
                    row("Date", systemImage: "calendar", subtitle: draft.due?.dayDescription(at: now, calendar: calendar)) {
                        if draft.dueDate != nil { expanded = expanded == .date ? nil : .date }
                    }
                }
                if expanded == .date, let due = draft.due {
                    DatePicker("Date", selection: $draft.date(or: due.date), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Toggle(isOn: $draft.timeOn(now, calendar: calendar).animation()) {
                    row("Time", systemImage: "clock", subtitle: draft.due?.timeDescription(calendar: calendar)) {
                        if draft.hasTime { expanded = expanded == .time ? nil : .time }
                    }
                }
                if expanded == .time, let due = draft.due, due.hasTime {
                    DatePicker("Time", selection: $draft.date(or: due.date), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            if draft.dueDate != nil {
                Section {
                    Picker(selection: $draft.repeats) {
                        ForEach(Reminder.Repeat.allCases, id: \.self) { Text($0.title).tag($0) }
                    } label: {
                        Label("Repeat", systemImage: "repeat").foregroundStyle(.primary, .secondary)
                    }
                }
            }
            if let failure = form.failure {
                Section { Text(failure).foregroundStyle(.red) } header: { Text("Not saved") }
            }
            if form.isNew {
                Section("More Options") { listPicker }
                Section {
                    NavigationLink {
                        SwiftUI::Form { details }
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
                    if form.isDirty { discardPresented = true } else { form.actions.cancel() }
                }
                .discardPrompt(discardTitle, isPresented: $discardPresented, discard: form.actions.cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: form.actions.save)
                    .buttonStyle(.glassProminent)
                    .disabled(draft.isBlank)
            }
        }
        .onAppear { titleFocused = form.isNew }
        .onChange(of: draft.dueDate != nil) { _, on in
            expanded = on ? .date : nil
            titleFocused = false
        }
        .onChange(of: draft.hasTime) { _, on in
            expanded = on ? .time : nil
            titleFocused = false
        }
    }

    private var quickBar: some SwiftUI::View {
        let (now, calendar) = (form.now, form.calendar)
        return HStack {
            Menu {
                ForEach(Reminders.Reminder.Due.Preset.allCases, id: \.self) { preset in
                    let date = preset.date(at: now, calendar: calendar)
                    Button(preset.title, systemImage: "\(calendar.component(.day, from: date)).calendar") {
                        draft.set(datePreset: preset, at: now, calendar: calendar)
                    }
                }
                Button("Custom", systemImage: "ellipsis") {
                    if draft.dueDate == nil { draft.set(datePreset: .today, at: now, calendar: calendar) }
                    expanded = .date
                }
            } label: {
                Label("Date & Time", systemImage: "calendar.badge.clock")
            }
            Spacer()
            Menu {
                Button("None") { draft.location = nil }
                ForEach(Reminder.Location.allCases, id: \.self) { location in
                    Button(location.title) { draft.location = location }
                }
            } label: {
                Label("Location", systemImage: "location")
            }
            Spacer()
            Button("Flag", systemImage: draft.flagged ? "flag.fill" : "flag") { draft.flagged.toggle() }
                .disabled(draft.isBlank)
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
        form.isNew ? "Are you sure you want to discard this new reminder?" : "Are you sure you want to discard your changes?"
    }

    private func row(_ title: String, systemImage: String, subtitle: String?, tap: @escaping () -> Void) -> some SwiftUI::View {
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

    private var listPicker: some SwiftUI::View {
        NavigationLink {
            SwiftUI::List(lists) { list in
                Button { draft.listID = list.id } label: {
                    HStack(spacing: 16) {
                        Organizing.List<Reminder>.Badge(color: SwiftUI::Color(Organizing.Color(list.color)))
                        Text(list.title).foregroundStyle(.primary)
                        Spacer()
                        if list.id == draft.listID {
                            Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("List")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            LabeledContent {
                Text(lists.first(id: draft.listID)?.title ?? "")
            } label: {
                Label {
                    Text("List")
                } icon: {
                    Organizing.List<Reminder>.Badge(color: lists.first(id: draft.listID).map { SwiftUI::Color(Organizing.Color($0.color)) } ?? .blue, size: 28)
                }
            }
        }
    }

    @ViewBuilder private var details: some SwiftUI::View {
        priorityPicker
        tagsRow
        flagToggle
        locationPicker
    }

    private var priorityPicker: some SwiftUI::View {
        Picker(selection: $draft.priority) {
            Text("None").tag(Reminder.Priority?.none)
            Divider()
            ForEach(Reminder.Priority.allCases.reversed(), id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Priority", systemImage: "exclamationmark").foregroundStyle(.primary, .secondary)
        }
    }

    private var tagsRow: some SwiftUI::View {
        Button { tagsPresented = true } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    if !tags.isEmpty {
                        Text(tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ")).lineLimit(1).truncationMode(.tail)
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
                Tag<Reminder>.Picker.SwiftUI(selection: $tags, tags: available, picker: Tag<Reminder>.Picker(actions: form.actions.tags))
            }
        }
    }

    private var flagToggle: some SwiftUI::View {
        Toggle(isOn: $draft.flagged) {
            Label("Flag", systemImage: "flag").foregroundStyle(.primary, .secondary)
        }
    }

    private var locationPicker: some SwiftUI::View {
        Picker(selection: $draft.location) {
            Text("None").tag(Reminder.Location?.none)
            Divider()
            ForEach(Reminder.Location.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Location", systemImage: "location").foregroundStyle(.primary, .secondary)
        }
    }
}
