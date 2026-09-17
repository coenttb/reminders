public import Foundation
public import Reminders
public import Reminders_Feature
public import Reminder
public import SwiftUI

extension Reminder.Row {
    public struct SwiftUI {
        private var reminder: Reminder
        private var highlight: Reminders.Highlight?
        private var completed: Bool
        private var color: SwiftUI::Color
        private var now: Date
        private var calendar: Calendar
        private var actions: Actions

        public init(reminder: Reminder, highlight: Reminders.Highlight? = nil, completed: Bool? = nil, color: SwiftUI::Color, now: Date, calendar: Calendar, actions: Actions) {
            self.reminder = reminder
            self.highlight = highlight
            self.completed = completed ?? reminder.completed
            self.color = color
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}

extension Reminder.Row.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(alignment: .top, spacing: 12) {
            Button { actions.complete(reminder.id) } label: {
                Image(systemName: completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(completed ? color : SwiftUI::Color(.systemGray3))
                    .font(.title2)
                    .frame(width: 26, height: 20)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(completed ? "Completed" : "Complete")
            Button { (actions.edit ?? actions.details)(reminder.id) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let priority = reminder.priority {
                            Text(priority.marks)
                                .foregroundStyle(completed ? .secondary : color)
                        }
                        Text(marked: highlight?.title ?? reminder.title).foregroundStyle(completed ? .secondary : .primary)
                        Spacer(minLength: 0)
                        if reminder.flagged, !completed {
                            Image(systemName: "flag.fill").foregroundStyle(.orange).font(.footnote)
                        }
                    }
                    .font(.body)
                    if subtitle != nil || !reminder.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            if !reminder.notes.isEmpty {
                                Text(marked: (highlight?.notes ?? reminder.notes).replacingOccurrences(of: "\n", with: " ")).lineLimit(2)
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
                .foregroundStyle(reminder.pastDue(at: now, calendar: calendar) ? SwiftUI::Color.red : SwiftUI::Color.secondary)
        }
        let tags = highlight.map { Text(marked: $0.tags.split(separator: " ").map { "#" + $0 }.joined(separator: " ")) } ?? Text(reminder.tagLine)
        switch (due, reminder.tagLine.isEmpty) {
        case (nil, true): return nil
        case let (due?, true): return due
        case (nil, false): return tags
        case let (due?, false): return Text("\(due)  \(tags)")
        }
    }
}

extension Text {
    // The matched parts of a search result, marked by the index, stand out.
    init(marked text: String) {
        var result = Text("")
        var rest = Substring(text)
        while let start = rest.range(of: Reminders.Highlight.open) {
            result = result + Text(rest[..<start.lowerBound])
            rest = rest[start.upperBound...]
            guard let end = rest.range(of: Reminders.Highlight.close) else { break }
            result = result + Text(rest[..<end.lowerBound]).fontWeight(.semibold).foregroundStyle(.tint)
            rest = rest[end.upperBound...]
        }
        self = result + Text(rest)
    }
}
