public import ComposableArchitecture2
public import Foundation
public import Reminder
import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminder.Editor {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminder.Editor.Feature>
        private var completed: Bool
        private var color: SwiftUI::Color
        private var now: Date
        private var calendar: Calendar
        private var focus: FocusState<Reminder.Focus?>.Binding

        public init(store: StoreOf<Reminder.Editor.Feature>, completed: Bool, color: SwiftUI::Color, now: Date, calendar: Calendar, focus: FocusState<Reminder.Focus?>.Binding) {
            self.store = store
            self.completed = completed
            self.color = color
            self.now = now
            self.calendar = calendar
            self.focus = focus
        }
    }
}

extension Reminder.Editor.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(alignment: .top, spacing: 12) {
            Button { store.send(.completeButtonTapped) } label: {
                Image(systemName: completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(completed ? color : SwiftUI::Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let priority = store.draft.priority {
                        Text(priority.marks).foregroundStyle(color)
                    }
                    TextField("", text: $store.draft.title)
                        .focused(focus, equals: .title)
                        .submitLabel(.return)
                        .onSubmit { store.send(.titleSubmitted) }
                    Button("Details", systemImage: "info.circle") { store.send(.detailsButtonTapped) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.primary)
                }
                TextField("Add Note", text: $store.draft.notes, axis: .vertical)
                    .font(.subheadline)
                    .focused(focus, equals: .notes)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        dateChip
                        if store.draft.due != nil {
                            timeChip
                            repeatChip
                        }
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
        .onAppear { if focus.wrappedValue == nil { focus.wrappedValue = .title } }
        .onChange(of: focus.wrappedValue) { _, focus in
            if focus == .notes { store.send(.notesFocused) }
        }
    }

    private var dateChip: some SwiftUI::View {
        let draft = store.draft
        return Menu {
            Button { store.send(.datePresetSelected(nil)) } label: { checked("None", draft.due == nil) }
            Divider()
            ForEach(Reminder.Editor.Preset.allCases, id: \.self) { preset in
                Button { store.send(.datePresetSelected(preset)) } label: {
                    let date = preset.date(at: now, calendar: calendar)
                    let current = draft.due.map { calendar.isDate($0.date, inSameDayAs: date) } ?? false
                    Label(preset.title, systemImage: current ? "checkmark" : "\(calendar.component(.day, from: date)).calendar")
                }
            }
            Button("Custom", systemImage: "ellipsis") { store.send(.customDateTapped) }
        } label: {
            chip(tinted: draft.due != nil) {
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
        let draft = store.draft
        return Menu {
            Button { store.send(.timePresetSelected(nil)) } label: { checked("None", draft.due?.hasTime != true) }
            Divider()
            ForEach(Reminder.Editor.Preset.Time.allCases, id: \.self) { preset in
                Button { store.send(.timePresetSelected(preset)) } label: {
                    let current = draft.due.map { $0.hasTime && calendar.component(.hour, from: $0.date) == preset.hour && calendar.component(.minute, from: $0.date) == 0 } == true
                    Text(preset.description(on: now, calendar: calendar) ?? preset.title)
                    Text(preset.title)
                    Image(systemName: current ? "checkmark" : "clock")
                }
            }
            Button("Custom", systemImage: "ellipsis") { store.send(.customDateTapped) }
        } label: {
            chip(tinted: draft.due?.hasTime == true) {
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
        let repeats = store.draft.repeats
        return Menu {
            Button { store.send(.repeatSelected(nil)) } label: { checked("Never", repeats == nil) }
            Divider()
            ForEach(Reminder.repeatOptions, id: \.self) { frequency in
                Button { store.send(.repeatSelected(frequency)) } label: {
                    checked(frequency.title, repeats?.frequency == frequency)
                }
            }
        } label: {
            chip(tinted: repeats != nil) {
                if let repeats {
                    Label(repeats.title, systemImage: "repeat")
                } else {
                    Label("Repeat", systemImage: "repeat").labelStyle(.iconOnly)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }
}

extension Reminder.Editor.SwiftUI {
    @ViewBuilder private func checked(_ title: String, _ on: Bool) -> some SwiftUI::View {
        if on { Label(title, systemImage: "checkmark") } else { Text(title) }
    }
}

extension Reminder.Editor.SwiftUI {
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
