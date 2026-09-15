import Foundation
public import Organizing
public import Reminders
import Standard_Library_Extensions
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
                .discardPrompt(discardTitle, isPresented: $discardPresented, discard: cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: save)
                    .buttonStyle(.glassProminent)
                    .disabled(reminder.isBlank)
            }
        }
        .onAppear { titleFocused = isNew }
        // Turning a row on opens its picker and drops the keyboard; turning it off
        // closes the picker. The toggles bind through key paths, so the view
        // effects live here rather than in a binding's setter.
        .onChange(of: reminder.due != nil) { _, on in
            expanded = on ? .date : nil
            titleFocused = false
        }
        .onChange(of: reminder.due?.hasTime == true) { _, on in
            expanded = on ? .time : nil
            titleFocused = false
        }
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
                Label { Text(list.title) } icon: { Organizing.List<Reminder>.Badge(color: list.color.swiftUI, size: 28) }.tag(list.id)
            }
        } label: {
            Label {
                Text("List")
            } icon: {
                Organizing.List<Reminder>.Badge(color: lists.first(id: reminder.list)?.color.swiftUI ?? .blue, size: 28)
            }
        }
        .pickerStyle(.navigationLink)
    }

    @ViewBuilder private var details: some SwiftUI.View {
        Picker(selection: $reminder.priority) {
            Text("None").tag(Reminder.Priority?.none)
            Divider()
            ForEach(Reminder.Priority.allCases.reversed(), id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Priority", systemImage: "exclamationmark").foregroundStyle(.primary, .secondary)
        }
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
        Toggle(isOn: $reminder.flagged) {
            Label("Flag", systemImage: "flag").foregroundStyle(.primary, .secondary)
        }
        Picker(selection: $reminder.location) {
            Text("None").tag(Reminder.Location?.none)
            Divider()
            ForEach(Reminder.Location.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
        } label: {
            Label("Location", systemImage: "location").foregroundStyle(.primary, .secondary)
        }
    }

}

extension Reminder {
    /// The Date row: on means due today, off clears the date and the time with it.
    fileprivate subscript(dueOn now: Date, calendar calendar: Calendar) -> Bool {
        get { due != nil }
        set { set(due: newValue ? calendar.startOfDay(for: now) : nil) }
    }

    /// The Time row: on proposes the next full hour and turns the date on with it.
    fileprivate subscript(timeOn now: Date, calendar calendar: Calendar) -> Bool {
        get { due?.hasTime == true }
        set { set(hasTime: newValue, at: now, calendar: calendar) }
    }

    /// The pickers edit the due date's moment, keeping whether the time matters.
    fileprivate subscript(date fallback: Date) -> Date {
        get { due?.date ?? fallback }
        set { set(due: newValue) }
    }
}

extension Binding<Reminder> {
    /// The toggles and pickers as key-path projections of the draft, so SwiftUI keeps their transaction.
    fileprivate func dueOn(_ now: Date, calendar: Calendar) -> Binding<Bool> { self[dynamicMember: \.[dueOn: now, calendar: calendar]] }
    fileprivate func timeOn(_ now: Date, calendar: Calendar) -> Binding<Bool> { self[dynamicMember: \.[timeOn: now, calendar: calendar]] }
    fileprivate func date(or fallback: Date) -> Binding<Date> { self[dynamicMember: \.[date: fallback]] }
}
