public import Foundation
public import Reminders
public import SwiftUI

extension Reminder {
    /// Which field of the row being edited holds the keyboard.
    public enum Focus: Hashable, Sendable {
        case title(Reminder.ID)
        case notes(Reminder.ID)
    }

    /// One reminder edited in place, as iOS 27 does it: a raised card with the circle,
    /// the title, the note, the Details button, and a row of chips whose menus offer
    /// the stock presets. The draft is edited through the binding; Return in the title
    /// and the Details button are the caller's.
    public struct Editor: SwiftUI.View {
        @Binding private var reminder: Reminder
        private var color: Color
        private var now: Date
        private var focus: FocusState<Reminder.Focus?>.Binding
        private var complete: () -> Void
        private var submit: () -> Void
        private var details: () -> Void

        public init(
            reminder: Binding<Reminder>,
            color: Color,
            now: Date,
            focus: FocusState<Reminder.Focus?>.Binding,
            complete: @escaping () -> Void,
            submit: @escaping () -> Void,
            details: @escaping () -> Void
        ) {
            self._reminder = reminder
            self.color = color
            self.now = now
            self.focus = focus
            self.complete = complete
            self.submit = submit
            self.details = details
        }
    }
}

extension Reminder.Editor {
    public var body: some SwiftUI.View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: complete) {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let priority = reminder.priority {
                        Text(String(repeating: "!", count: priority.rawValue)).foregroundStyle(color)
                    }
                    TextField("", text: $reminder.title)
                        .focused(focus, equals: .title(reminder.id))
                        .submitLabel(.return)
                        .onSubmit(submit)
                    Button("Details", systemImage: "info.circle", action: details)
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
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 14, trailing: 6))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        // Moving on to the note with no title names the reminder, as the stock app does.
        .onChange(of: focus.wrappedValue) { _, focus in
            if focus == .notes(reminder.id), reminder.isBlank { reminder.title = "New Reminder" }
        }
    }

    private var dateChip: some SwiftUI.View {
        Menu {
            Button { reminder.set(datePreset: nil, at: now) } label: { checked("None", reminder.due == nil) }
            Divider()
            ForEach(Reminder.DatePreset.allCases, id: \.self) { preset in
                Button { reminder.set(datePreset: preset, at: now) } label: {
                    let current = reminder.due.map { Calendar.current.isDate($0, inSameDayAs: preset.date(at: now)) } ?? false
                    Label(preset.title, systemImage: current ? "checkmark" : "calendar")
                }
            }
            Button("Custom", systemImage: "ellipsis", action: details)
        } label: {
            chip(tinted: reminder.due != nil) {
                if let day = reminder.dayDescription(at: now) {
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
            Button { reminder.set(timePreset: nil, at: now) } label: { checked("None", !reminder.hasTime) }
            Divider()
            ForEach(Reminder.TimePreset.allCases, id: \.self) { preset in
                Button { reminder.set(timePreset: preset, at: now) } label: {
                    let current = reminder.hasTime && reminder.due.map { Calendar.current.component(.hour, from: $0) == preset.hour && Calendar.current.component(.minute, from: $0) == 0 } == true
                    Text(String(format: "%02d:00", preset.hour))
                    Text(preset.title)
                    Image(systemName: current ? "checkmark" : "clock")
                }
            }
            Button("Custom", systemImage: "ellipsis", action: details)
        } label: {
            chip(tinted: reminder.hasTime) {
                if let time = reminder.timeDescription() {
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
            .background(tinted ? color.opacity(0.15) : Color(.tertiarySystemFill), in: .capsule)
            .contentShape(.capsule)
    }
}
