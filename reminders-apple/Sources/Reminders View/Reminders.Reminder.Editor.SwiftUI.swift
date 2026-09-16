public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI

extension Reminders.Reminder.Editor {
    public struct SwiftUI {
        @Binding private var draft: Reminder.Record.Draft
        private var color: SwiftUI::Color
        private var focus: FocusState<Reminder.Focus?>.Binding
        private var view: Reminders.Reminder.Editor

        public init(draft: Binding<Reminder.Record.Draft>, color: SwiftUI::Color, focus: FocusState<Reminder.Focus?>.Binding, view: Reminders.Reminder.Editor) {
            self._draft = draft
            self.color = color
            self.focus = focus
            self.view = view
        }
    }
}

extension Reminders.Reminder.Editor.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let (id, actions) = (view.id, view.actions)
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(id) } label: {
                Image(systemName: draft.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(draft.completed ? color : SwiftUI::Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let priority = draft.priority {
                        Text(priority.marks).foregroundStyle(color)
                    }
                    TextField("", text: $draft.title)
                        .focused(focus, equals: .title(id))
                        .submitLabel(.return)
                        .onSubmit(actions.submit)
                    Button("Details", systemImage: "info.circle") { actions.details(id) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.primary)
                }
                TextField("Add Note", text: $draft.notes, axis: .vertical)
                    .font(.subheadline)
                    .focused(focus, equals: .notes(id))
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        dateChip
                        if draft.dueDate != nil {
                            timeChip
                            repeatChip
                        }
                        locationChip
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 12, trailing: 10))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SwiftUI::Color(.systemBackground))
                .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 14, trailing: 6))
        .listRowSeparator(.hidden)
        .listRowBackground(SwiftUI::Color.clear)
        .onChange(of: focus.wrappedValue) { _, focus in
            if focus == .notes(id), draft.isBlank { draft.title = "New Reminder" }
        }
    }

    private var dateChip: some SwiftUI::View {
        let (id, now, calendar, actions) = (view.id, view.now, view.calendar, view.actions)
        return Menu {
            Button { actions.setDate(id, nil) } label: { checked("None", draft.dueDate == nil) }
            Divider()
            ForEach(Reminders.Reminder.Due.Preset.allCases, id: \.self) { preset in
                Button { actions.setDate(id, preset) } label: {
                    let date = preset.date(at: now, calendar: calendar)
                    let current = draft.dueDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    Label(preset.title, systemImage: current ? "checkmark" : "\(calendar.component(.day, from: date)).calendar")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(id) }
        } label: {
            chip(tinted: draft.dueDate != nil) {
                if let day = draft.due?.dayDescription(at: now, calendar: calendar) {
                    Label(day, systemImage: "calendar")
                } else {
                    Label("Date", systemImage: "calendar").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var timeChip: some SwiftUI::View {
        let (id, now, calendar, actions) = (view.id, view.now, view.calendar, view.actions)
        return Menu {
            Button { actions.setTime(id, nil) } label: { checked("None", !draft.hasTime) }
            Divider()
            ForEach(Reminders.Reminder.Due.Preset.Time.allCases, id: \.self) { preset in
                Button { actions.setTime(id, preset) } label: {
                    let current = draft.due.map { $0.hasTime && calendar.component(.hour, from: $0.date) == preset.hour && calendar.component(.minute, from: $0.date) == 0 } == true
                    Text(preset.description(on: now, calendar: calendar) ?? preset.title)
                    Text(preset.title)
                    Image(systemName: current ? "checkmark" : "clock")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(id) }
        } label: {
            chip(tinted: draft.hasTime) {
                if let time = draft.due?.timeDescription(calendar: calendar) {
                    Label(time, systemImage: "clock")
                } else {
                    Label("Time", systemImage: "clock").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var repeatChip: some SwiftUI::View {
        Menu {
            ForEach(Reminder.Repeat.allCases, id: \.self) { option in
                Button { draft.repeats = option } label: { checked(option.title, draft.repeats == option) }
            }
        } label: {
            chip(tinted: draft.repeats != .never) {
                if draft.repeats == .never {
                    Label("Repeat", systemImage: "repeat").labelStyle(.iconOnly)
                } else {
                    Label(draft.repeats.title, systemImage: "repeat")
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var locationChip: some SwiftUI::View {
        Menu {
            Button { draft.location = nil } label: { checked("None", draft.location == nil) }
            Divider()
            ForEach(Reminder.Location.allCases, id: \.self) { location in
                Button { draft.location = location } label: { checked(location.title, draft.location == location) }
            }
        } label: {
            chip(tinted: draft.location != nil) {
                if let location = draft.location {
                    Label(location.title, systemImage: "location")
                } else {
                    Label("Location", systemImage: "location").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }
}

extension Reminders.Reminder.Editor.SwiftUI {
    @ViewBuilder private func checked(_ title: String, _ on: Bool) -> some SwiftUI::View {
        if on { Label(title, systemImage: "checkmark") } else { Text(title) }
    }
}

extension Reminders.Reminder.Editor.SwiftUI {
    private func chip(tinted: Bool, @ViewBuilder _ content: () -> some SwiftUI::View) -> some SwiftUI::View {
        content()
            .font(.subheadline.weight(.medium))
            .foregroundStyle(tinted ? color : .primary)
            .padding(.horizontal, tinted ? 10 : 8)
            .frame(height: 36)
            .frame(minWidth: 36)
            .background(tinted ? color.opacity(0.15) : SwiftUI::Color(.tertiarySystemFill), in: .capsule)
            .contentShape(.capsule)
    }
}
