public import Foundation
public import Reminders
import Reminders_Interface
public import SwiftUI
public import Tagged

extension Reminders.Reminder {
    public struct Row {
        private var reminder: Reminder
        private var color: SwiftUI.Color
        private var now: Date
        private var calendar: Calendar
        private var actions: Actions

        public init(_ reminder: Reminder, color: SwiftUI.Color, now: Date, calendar: Calendar, actions: Actions) {
            self.reminder = reminder
            self.color = color
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}

extension Reminders.Reminder.Row {
    public struct Actions {
        public var complete: (Reminder.ID) -> Void
        public var delete: (Reminder.ID) -> Void
        public var details: (Reminder.ID) -> Void
        public var edit: ((Reminder.ID) -> Void)?

        public init(
            complete: @escaping (Reminder.ID) -> Void,
            delete: @escaping (Reminder.ID) -> Void,
            details: @escaping (Reminder.ID) -> Void,
            edit: ((Reminder.ID) -> Void)? = nil
        ) {
            self.complete = complete
            self.delete = delete
            self.details = details
            self.edit = edit
        }
    }
}

extension Reminders.Reminder.Row: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(reminder.id) } label: {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : SwiftUI.Color(.systemGray3))
                    .font(.title2)
                    .frame(width: 26, height: 20)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(reminder.completed ? "Completed" : "Complete")
            Button { (actions.edit ?? actions.details)(reminder.id) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let priority = reminder.priority {
                            Text(priority.marks)
                                .foregroundStyle(reminder.completed ? .secondary : color)
                        }
                        Text(reminder.title).foregroundStyle(reminder.completed ? .secondary : .primary)
                        Spacer(minLength: 0)
                        if reminder.flagged, !reminder.completed {
                            Image(systemName: "flag.fill").foregroundStyle(.orange).font(.footnote)
                        }
                    }
                    .font(.body)
                    if subtitle != nil || !reminder.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            if !reminder.notes.isEmpty {
                                Text(reminder.notes.replacingOccurrences(of: "\n", with: " ")).lineLimit(2)
                            }
                            if let subtitle { subtitle }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) { actions.delete(reminder.id) }
            Button("Details", systemImage: "info.circle") { actions.details(reminder.id) }.tint(.gray)
        }
    }

    private var subtitle: Text? {
        let due = reminder.due.map { due in
            Text(due.description(at: now, calendar: calendar))
                .foregroundStyle(reminder.pastDue(at: now, calendar: calendar) ? SwiftUI.Color.red : SwiftUI.Color.secondary)
        }
        switch (due, reminder.tagLine.isEmpty) {
        case (nil, true): return nil
        case let (due?, true): return due
        case (nil, false): return Text(reminder.tagLine)
        case let (due?, false): return Text("\(due)  \(reminder.tagLine)")
        }
    }
}
