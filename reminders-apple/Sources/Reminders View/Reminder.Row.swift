public import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Reminder {
    /// One reminder at rest in a detail or search: the completion circle, the title with
    /// priority marks and flag, and one gray line of due date, notes, and tags.
    /// Tapping the text edits the row in place where the caller offers it, otherwise
    /// opens details; Details and Delete are the swipe actions, as in iOS 27.
    public struct Row: SwiftUI.View {
        private var reminder: Reminder
        private var color: Color
        private var now: Date
        private var calendar: Calendar
        private var actions: Actions

        public init(_ reminder: Reminder, color: Color, now: Date, calendar: Calendar, actions: Actions) {
            self.reminder = reminder
            self.color = color
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}

extension Reminder.Row {
    /// What a row asks of its owner, keyed by the reminder; `edit` only where rows edit in place.
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

extension Reminder.Row {
    public var body: some SwiftUI.View {
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(reminder.id) } label: {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(reminder.completed ? "Completed" : "Complete")
            Button { (actions.edit ?? actions.details)(reminder.id) } label: {
                VStack(alignment: .leading, spacing: 2) {
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
        .padding(.vertical, 2)
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) { actions.delete(reminder.id) }
            Button("Details", systemImage: "info.circle") { actions.details(reminder.id) }.tint(.gray)
        }
    }

    private var subtitle: Text? {
        let due = reminder.dueDescription(at: now, calendar: calendar).map { text in
            Text(text).foregroundStyle(reminder.pastDue(at: now, calendar: calendar) ? Color.red : Color.secondary)
        }
        switch (due, reminder.hashtags.isEmpty) {
        case (nil, true): return nil
        case let (due?, true): return due
        case (nil, false): return Text(reminder.hashtags)
        case let (due?, false): return Text("\(due)  \(reminder.hashtags)")
        }
    }
}
