public import Foundation
public import Reminders
public import Reminders_Application
public import SwiftUI

extension Reminder {
    /// Which field of the row being edited holds the keyboard.
    public enum Focus: Hashable, Sendable {
        case title(Reminder.ID)
        case notes(Reminder.ID)
    }

    /// One reminder edited in place, as iOS 27 does it: a raised card with the circle,
    /// the title, the note, the Details button, and a row of chips whose menus offer
    /// the stock presets. Typing edits the draft through the binding; the chips, Return
    /// in the title, the circle, and Details are intents the caller decides.
    public struct Editor: SwiftUI.View {
        @Binding private var reminder: Reminder
        private var color: SwiftUI.Color
        private var now: Date
        private var calendar: Calendar
        private var focus: FocusState<Reminder.Focus?>.Binding
        private var actions: Actions

        public init(
            reminder: Binding<Reminder>,
            color: SwiftUI.Color,
            now: Date,
            calendar: Calendar,
            focus: FocusState<Reminder.Focus?>.Binding,
            actions: Actions
        ) {
            self._reminder = reminder
            self.color = color
            self.now = now
            self.calendar = calendar
            self.focus = focus
            self.actions = actions
        }
    }
}

extension Reminder.Editor {
    /// What the card asks of its owner, keyed by the reminder. The Date and Time chips
    /// are intents because they run calendar rules on the owner's clock, not the view's.
    public struct Actions {
        public var complete: (Reminder.ID) -> Void
        public var details: (Reminder.ID) -> Void
        public var submit: () -> Void
        public var setDate: (Reminder.ID, Reminder.Due.Preset?) -> Void
        public var setTime: (Reminder.ID, Reminder.Due.Preset.Time?) -> Void

        public init(
            complete: @escaping (Reminder.ID) -> Void,
            details: @escaping (Reminder.ID) -> Void,
            submit: @escaping () -> Void,
            setDate: @escaping (Reminder.ID, Reminder.Due.Preset?) -> Void,
            setTime: @escaping (Reminder.ID, Reminder.Due.Preset.Time?) -> Void
        ) {
            self.complete = complete
            self.details = details
            self.submit = submit
            self.setDate = setDate
            self.setTime = setTime
        }
    }
}

extension Reminder.Editor {
    public var body: some SwiftUI.View {
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(reminder.id) } label: {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : SwiftUI.Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let priority = reminder.priority {
                        Text(priority.marks).foregroundStyle(color)
                    }
                    TextField("", text: $reminder.title)
                        .focused(focus, equals: .title(reminder.id))
                        .submitLabel(.return)
                        .onSubmit(actions.submit)
                    Button("Details", systemImage: "info.circle") { actions.details(reminder.id) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.primary)
                }
                TextField("Add Note", text: $reminder.notes, axis: .vertical)
                    .font(.subheadline)
                    .focused(focus, equals: .notes(reminder.id))
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
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 14, trailing: 12))
        // The card is the content's own background, not the row's: a row background is
        // clipped to the row, which cut the shadow and the corners.
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SwiftUI.Color(.systemBackground))
                .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 14, trailing: 6))
        .listRowSeparator(.hidden)
        .listRowBackground(SwiftUI.Color.clear)
        // Moving on to the note with no title names the reminder, as the stock app does.
        .onChange(of: focus.wrappedValue) { _, focus in
            if focus == .notes(reminder.id), reminder.isBlank { reminder.title = "New Reminder" }
        }
    }

    private var dateChip: some SwiftUI.View {
        Menu {
            Button { actions.setDate(reminder.id, nil) } label: { checked("None", reminder.due == nil) }
            Divider()
            ForEach(Reminder.Due.Preset.allCases, id: \.self) { preset in
                Button { actions.setDate(reminder.id, preset) } label: {
                    let current = reminder.due.map { calendar.isDate($0.date, inSameDayAs: preset.date(at: now, calendar: calendar)) } ?? false
                    Label(preset.title, systemImage: current ? "checkmark" : "calendar")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(reminder.id) }
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
            Button { actions.setTime(reminder.id, nil) } label: { checked("None", reminder.due?.hasTime != true) }
            Divider()
            ForEach(Reminder.Due.Preset.Time.allCases, id: \.self) { preset in
                Button { actions.setTime(reminder.id, preset) } label: {
                    let current = reminder.due.map { $0.hasTime && calendar.component(.hour, from: $0.date) == preset.hour && calendar.component(.minute, from: $0.date) == 0 } == true
                    Text(preset.description(on: now, calendar: calendar) ?? preset.title)
                    Text(preset.title)
                    Image(systemName: current ? "checkmark" : "clock")
                }
            }
            Button("Custom", systemImage: "ellipsis") { actions.details(reminder.id) }
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

extension Reminder.Editor {
    /// A menu item with a checkmark when it is the current value.
    @ViewBuilder private func checked(_ title: String, _ on: Bool) -> some SwiftUI.View {
        if on { Label(title, systemImage: "checkmark") } else { Text(title) }
    }
}

extension Reminder.Editor {
    /// A chip's face: a gray circle when unset, a tinted capsule naming the value when set.
    /// The styling is part of the menu's label, so the menu grows out of the whole chip.
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
