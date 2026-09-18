public import Foundation
public import Reminders
public import Reminders_Feature
public import Reminder
public import SwiftUI

extension Reminder.Row {
    public struct SwiftUI {
        private var reminder: Reminder
        private var highlight: Reminders.Highlight?
        // The list's name, on a screen that gathers rows from every list without naming them above.
        private var list: String?
        // On a screen that sections by day the row's subtitle names the time alone.
        private var dated: Bool
        // The Completed screen names when each row was completed.
        private var completion: Bool
        private var completed: Bool
        private var color: SwiftUI::Color
        private var now: Date
        private var calendar: Calendar
        private var actions: Actions

        public init(reminder: Reminder, highlight: Reminders.Highlight? = nil, list: String? = nil, dated: Bool = false, completion: Bool = false, completed: Bool? = nil, color: SwiftUI::Color, now: Date, calendar: Calendar, actions: Actions) {
            self.reminder = reminder
            self.highlight = highlight
            self.list = list
            self.dated = dated
            self.completion = completion
            self.completed = completed ?? reminder.isCompleted
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
                                Text(marked: highlight?.notes ?? reminder.notes).lineLimit(2)
                            }
                            if let subtitle { subtitle }
                            if completion, let completed = reminder.completed {
                                Text("Completed: " + Reminder.Due.moment(completed).description(at: now, calendar: calendar))
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 22)
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) { actions.delete(reminder.id) }
            Button("Details", systemImage: "info") { actions.details(reminder.id) }.tint(.gray)
        }
    }

    private var subtitle: Text? {
        let due = reminder.due.flatMap { due -> Text? in
            let description = dated && !completion ? due.timeDescription(calendar: calendar) : due.description(at: now, calendar: calendar)
            return description.map { Text($0).foregroundStyle(reminder.pastDue(at: now, calendar: calendar) ? SwiftUI::Color.red : SwiftUI::Color.secondary) }
        }
        let tags = highlight.map { Text(marked: $0.tags.split(separator: " ").map { "#" + $0 }.joined(separator: " ")) } ?? Text(reminder.tagLine)
        let parts = [list.map { Text($0) }, due, reminder.tagLine.isEmpty ? nil : tags].compactMap { $0 }
        guard let first = parts.first else { return nil }
        return parts.dropFirst().reduce(first) { Text("\($0)  \($1)") }
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
