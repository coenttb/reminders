public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI

extension Reminders.Reminder.Row {
    public struct SwiftUI {
        private var row: Reminder.Record.Row
        private var color: SwiftUI::Color
        private var view: Reminders.Reminder.Row

        public init(row: Reminder.Record.Row, color: SwiftUI::Color, view: Reminders.Reminder.Row) {
            self.row = row
            self.color = color
            self.view = view
        }
    }
}

extension Reminders.Reminder.Row.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let reminder = row.reminder
        let actions = view.actions
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(reminder.id) } label: {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : SwiftUI::Color(.systemGray3))
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
        let reminder = row.reminder
        let (now, calendar) = (view.now, view.calendar)
        let due = reminder.due.map { due in
            Text(due.description(at: now, calendar: calendar))
                .foregroundStyle(reminder.pastDue(at: now, calendar: calendar) ? SwiftUI::Color.red : SwiftUI::Color.secondary)
        }
        switch (due, row.tagLine.isEmpty) {
        case (nil, true): return nil
        case let (due?, true): return due
        case (nil, false): return Text(row.tagLine)
        case let (due?, false): return Text("\(due)  \(row.tagLine)")
        }
    }
}
