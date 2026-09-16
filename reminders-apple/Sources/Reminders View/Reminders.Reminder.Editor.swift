public import Foundation
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI
public import Tagged

extension Reminders.Reminder {
    public struct Editor {
        private var id: Reminder.ID
        @Binding private var reminder: Reminder.Record.Draft
        private var color: SwiftUI.Color
        private var now: Date
        private var calendar: Calendar
        private var focus: FocusState<Reminder.Focus?>.Binding
        private var actions: Actions

        public init(
            id: Reminder.ID,
            draft: Binding<Reminder.Record.Draft>,
            color: SwiftUI.Color,
            now: Date,
            calendar: Calendar,
            focus: FocusState<Reminder.Focus?>.Binding,
            actions: Actions
        ) {
            self.id = id
            self._reminder = draft
            self.color = color
            self.now = now
            self.calendar = calendar
            self.focus = focus
            self.actions = actions
        }
    }
}
extension Reminders.Reminder.Editor: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(id) } label: {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : SwiftUI.Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let priority = reminder.priority {
                        Text(priority.marks).foregroundStyle(color)
                    }
                    TextField("", text: $reminder.title)
                        .focused(focus, equals: .title(id))
                        .submitLabel(.return)
                        .onSubmit(actions.submit)
                    Button("Details", systemImage: "info.circle") { actions.details(id) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.primary)
                }
                TextField("Add Note", text: $reminder.notes, axis: .vertical)
                    .font(.subheadline)
                    .focused(focus, equals: .notes(id))
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        dateChip
                        if reminder.due != nil {
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
                .fill(SwiftUI.Color(.systemBackground))
                .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 14, trailing: 6))
        .listRowSeparator(.hidden)
        .listRowBackground(SwiftUI.Color.clear)
        .onChange(of: focus.wrappedValue) { _, focus in
            if focus == .notes(id), reminder.isBlank { reminder.title = "New Reminder" }
        }
    }

    private var dateChip: some SwiftUI.View {
        Menu {
            Button { actions.setDate(id, nil) } label: { checked("None", reminder.due == nil) }
            Divider()
            ForEach(Reminders.Reminder.Due.Preset.allCases, id: \.self) { preset in
                Button { actions.setDate(id, preset) } label: {
                    let date = preset.date(at: now, calendar: calendar)
                    let current = reminder.due.map { calendar.isDate($0.date, inSameDayAs: date) } ?? false
                    Label(preset.title, systemImage: current ? "checkmark" : "\(calendar.component(.day, from: date)).calendar")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(id) }
        } label: {
            chip(tinted: reminder.due != nil) {
                if let day = reminder.due?.dayDescription(at: now, calendar: calendar) {
                    Label(day, systemImage: "calendar")
                } else {
                    Label("Date", systemImage: "calendar").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var timeChip: some SwiftUI.View {
        Menu {
            Button { actions.setTime(id, nil) } label: { checked("None", reminder.due?.hasTime != true) }
            Divider()
            ForEach(Reminders.Reminder.Due.Preset.Time.allCases, id: \.self) { preset in
                Button { actions.setTime(id, preset) } label: {
                    let current = reminder.due.map { $0.hasTime && calendar.component(.hour, from: $0.date) == preset.hour && calendar.component(.minute, from: $0.date) == 0 } == true
                    Text(preset.description(on: now, calendar: calendar) ?? preset.title)
                    Text(preset.title)
                    Image(systemName: current ? "checkmark" : "clock")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(id) }
        } label: {
            chip(tinted: reminder.due?.hasTime == true) {
                if let time = reminder.due?.timeDescription(calendar: calendar) {
                    Label(time, systemImage: "clock")
                } else {
                    Label("Time", systemImage: "clock").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var repeatChip: some SwiftUI.View {
        Menu {
            ForEach(Reminder.Repeat.allCases, id: \.self) { option in
                Button { reminder.repeats = option } label: { checked(option.title, reminder.repeats == option) }
            }
        } label: {
            chip(tinted: reminder.repeats != .never) {
                if reminder.repeats == .never {
                    Label("Repeat", systemImage: "repeat").labelStyle(.iconOnly)
                } else {
                    Label(reminder.repeats.title, systemImage: "repeat")
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var locationChip: some SwiftUI.View {
        Menu {
            Button { reminder.location = nil } label: { checked("None", reminder.location == nil) }
            Divider()
            ForEach(Reminder.Location.allCases, id: \.self) { location in
                Button { reminder.location = location } label: { checked(location.title, reminder.location == location) }
            }
        } label: {
            chip(tinted: reminder.location != nil) {
                if let location = reminder.location {
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

extension Reminders.Reminder.Editor {
    @ViewBuilder private func checked(_ title: String, _ on: Bool) -> some SwiftUI.View {
        if on { Label(title, systemImage: "checkmark") } else { Text(title) }
    }
}

extension Reminders.Reminder.Editor {
    private func chip(tinted: Bool, @ViewBuilder _ content: () -> some SwiftUI.View) -> some SwiftUI.View {
        content()
            .font(.subheadline.weight(.medium))
            .foregroundStyle(tinted ? color : .primary)
            .padding(.horizontal, tinted ? 10 : 8)
            .frame(height: 36)
            .frame(minWidth: 36)
            .background(tinted ? color.opacity(0.15) : SwiftUI.Color(.tertiarySystemFill), in: .capsule)
            .contentShape(.capsule)
    }
}
