public import ComposableArchitecture2
import Dependencies
public import Foundation
public import Models
public import Reminder
import Reminders
public import Reminders_Feature
import Standard_Library_Extensions
public import SwiftUI
import Tagged

extension Reminder.Form {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminder.Form.Feature>
        private var lists: [Models.List<Reminder>]
        private var available: [Tag<Reminder>]
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @State private var tagsPresented = false
        @State private var discardPresented = false
        @State private var expanded: Expansion?
        @FocusState private var titleFocused: Bool
        @FocusState private var notesFocused: Bool

        public init(store: StoreOf<Reminder.Form.Feature>, lists: [Models.List<Reminder>], available: [Tag<Reminder>]) {
            self.store = store
            self.lists = lists
            self.available = available
        }

        private enum Expansion { case date, time }
    }
}

extension Reminder.Form.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let draft = store.draft
        SwiftUI::Form {
            if store.part == .all {
                Section {
                    TextField("Title", text: $store.draft.title, axis: .vertical)
                        .font(.title2)
                        .focused($titleFocused)
                        .listRowSeparator(.hidden)
                    TextField("Notes", text: $store.draft.notes, axis: .vertical)
                        .lineLimit(1...6)
                        .focused($notesFocused)
                }
                .listSectionMargins(.top, 6)
            }
            Section("Date & Time") {
                Toggle(isOn: $store.draft.dueOn(now, calendar: calendar).animation()) {
                    row("Date", systemImage: "calendar", subtitle: draft.due?.dayDescription(at: now, calendar: calendar, otherwise: .complete)) {
                        if draft.due != nil { expanded = expanded == .date ? nil : .date }
                    }
                }
                if expanded == .date, let due = draft.due {
                    DatePicker("Date", selection: $store.draft.date(or: due.date), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 22))
                }
                Toggle(isOn: $store.draft.timeOn(now, calendar: calendar).animation()) {
                    row("Time", systemImage: "clock", subtitle: draft.due?.timeDescription(calendar: calendar)) {
                        if draft.due?.hasTime == true { expanded = expanded == .time ? nil : .time }
                    }
                }
                if expanded == .time, let due = draft.due, due.hasTime {
                    DatePicker("Time", selection: $store.draft.date(or: due.date), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            if draft.due != nil {
                Section {
                    Picker(selection: $store.draft.repeatFrequency(in: calendar)) {
                        Text("Never").tag(Calendar.RecurrenceRule.Frequency?.none)
                        Divider()
                        ForEach(Reminder.repeatOptions, id: \.self) { Text($0.title).tag(Optional($0)) }
                    } label: {
                        Label("Repeat", systemImage: "repeat").foregroundStyle(.primary, .secondary)
                    }
                }
                .listSectionSpacing(10)
            }
            if let failure = store.failure {
                Section { Text(failure).foregroundStyle(.red) } header: { Text("Not saved") }
            }
            if store.part == .dates {
                EmptyView()
            } else if store.isNew {
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
                Section { priorityPicker }.listSectionSpacing(10)
                Section {
                    tagsRow
                    flagToggle
                }
                .listSectionSpacing(10)
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
                    if store.isDirty { discardPresented = true } else { store.send(.cancelButtonTapped) }
                }
                .discardPrompt(discardTitle, isPresented: $discardPresented) { store.send(.cancelButtonTapped) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") { store.send(.saveButtonTapped) }
                    .buttonStyle(.glassProminent)
                    .disabled(draft.isBlank)
            }
        }
        .onAppear {
            titleFocused = store.isNew
            // The Date & Time sheet opens on the calendar, as the stock one does.
            if store.part == .dates { expanded = store.draft.due?.hasTime == true ? .time : .date }
        }
        .onChange(of: draft.due != nil) { _, on in
            expanded = on ? .date : nil
            titleFocused = false
        }
        .onChange(of: draft.due?.hasTime == true) { _, on in
            expanded = on ? .time : nil
            titleFocused = false
        }
    }

    private var quickBar: some SwiftUI::View {
        let draft = store.draft
        return HStack {
            Menu {
                ForEach(Reminder.Editor.Preset.allCases, id: \.self) { preset in
                    let date = preset.date(at: now, calendar: calendar)
                    Button(preset.title, systemImage: "\(calendar.component(.day, from: date)).calendar") {
                        store.send(.datePresetSelected(preset))
                    }
                }
                Button("Custom", systemImage: "ellipsis") {
                    if draft.due == nil { store.send(.datePresetSelected(.today)) }
                    expanded = .date
                }
            } label: {
                Label("Date & Time", systemImage: "calendar.badge.clock")
            }
            Spacer()
            Button("Flag", systemImage: draft.flagged ? "flag.fill" : "flag") { store.send(.flagToggled) }
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
        store.isNew ? "Are you sure you want to discard this new reminder?" : "Are you sure you want to discard your changes?"
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
        let draft = store.draft
        return NavigationLink {
            SwiftUI::List(lists) { list in
                Button { store.send(.listSelected(list.id)) } label: {
                    HStack(spacing: 16) {
                        Models.List<Reminder>.Badge(color: SwiftUI::Color(list.color))
                        Text(list.title).foregroundStyle(.primary)
                        Spacer()
                        if list.id == draft.list {
                            Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("List")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            LabeledContent {
                Text(lists.first(id: draft.list)?.title ?? "")
            } label: {
                Label {
                    Text("List")
                } icon: {
                    Models.List<Reminder>.Badge(color: lists.first(id: draft.list).map { SwiftUI::Color($0.color) } ?? .blue, size: 28)
                }
            }
        }
    }

    @ViewBuilder private var details: some SwiftUI::View {
        priorityPicker
        tagsRow
        flagToggle
    }

    private var priorityPicker: some SwiftUI::View {
        Picker(selection: $store.draft.priority) {
            Text("None").tag(Reminder.Priority?.none)
            Divider()
            ForEach(Reminder.Priority.allCases.reversed(), id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Priority", systemImage: "exclamationmark").foregroundStyle(.primary, .secondary)
        }
    }

    private var tagsRow: some SwiftUI::View {
        let draft = store.draft
        return Button { tagsPresented = true } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    if !draft.tags.isEmpty {
                        Text(draft.tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ")).lineLimit(1).truncationMode(.tail)
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
                Tag<Reminder>.Picker.SwiftUI(store: store, tags: available)
            }
        }
    }

    private var flagToggle: some SwiftUI::View {
        Toggle(isOn: $store.draft.flagged) {
            Label("Flag", systemImage: "flag").foregroundStyle(.primary, .secondary)
        }
    }
}
