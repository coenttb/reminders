public import Foundation
public import Reminders
public import SwiftUI
import Tagged

extension Reminder {
    /// One reminder in a detail or search: the completion circle, the title with
    /// priority marks and flag, and one gray line of due date, notes, and tags.
    /// Tapping the text opens details; flag, delete, and details are swipe actions.
    public struct Row: SwiftUI.View {
        private var reminder: Reminder
        private var color: Color
        private var now: Date
        private var complete: () -> Void
        private var flag: () -> Void
        private var delete: () -> Void
        private var details: () -> Void

        public init(
            _ reminder: Reminder,
            color: Color,
            now: Date,
            complete: @escaping () -> Void,
            flag: @escaping () -> Void,
            delete: @escaping () -> Void,
            details: @escaping () -> Void
        ) {
            self.reminder = reminder
            self.color = color
            self.now = now
            self.complete = complete
            self.flag = flag
            self.delete = delete
            self.details = details
        }
    }
}

extension Reminder.Row {
    public var body: some SwiftUI.View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: complete) {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? color : Color(.systemGray3))
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(reminder.completed ? "Completed" : "Complete")
            Button(action: details) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let priority = reminder.priority {
                            Text(String(repeating: "!", count: priority.rawValue))
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
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            Button(reminder.flagged ? "Unflag" : "Flag", systemImage: "flag", action: flag).tint(.orange)
            Button("Details", systemImage: "info.circle", action: details).tint(.gray)
        }
    }

    private var subtitle: Text? {
        let due = reminder.dueDescription(at: now).map { text in
            Text(text).foregroundStyle(reminder.pastDue(at: now) ? Color.red : Color.secondary)
        }
        let tags = reminder.sortedTags.map { "#\($0)" }.joined(separator: " ")
        switch (due, tags.isEmpty) {
        case (nil, true): return nil
        case let (due?, true): return due
        case (nil, false): return Text(tags)
        case let (due?, false): return Text("\(due)  \(tags)")
        }
    }
}
