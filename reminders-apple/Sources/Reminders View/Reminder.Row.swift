public import Foundation
public import Reminders
public import SwiftUI
import Tagged

extension Reminder {
    /// One reminder in a detail or search: the completion circle, title with
    /// priority marks, notes, due date, and tags; flag, delete, and details are
    /// swipe actions. Text may carry Markdown emphasis from a search highlight.
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
        HStack {
            HStack(alignment: .firstTextBaseline) {
                Button(action: complete) {
                    Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                        .foregroundStyle(reminder.completed ? color : .gray)
                        .font(.title2)
                        .padding(.trailing, 5)
                }
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        if let priority = reminder.priority {
                            Text(String(repeating: "!", count: priority.rawValue))
                                .foregroundStyle(reminder.completed ? .gray : color)
                        }
                        Text(reminder.title).foregroundStyle(reminder.completed ? .gray : .primary)
                    }
                    .font(.title3)
                    if !reminder.notes.isEmpty {
                        Text(reminder.notes.replacingOccurrences(of: "\n", with: " "))
                            .font(.subheadline).foregroundStyle(.gray).lineLimit(2)
                    }
                    subtitle
                }
            }
            Spacer()
            if !reminder.completed {
                HStack {
                    if reminder.flagged { Image(systemName: "flag.fill").foregroundStyle(.orange) }
                    Button(action: details) { Image(systemName: "info.circle") }.tint(color)
                }
            }
        }
        .buttonStyle(.borderless)
        .swipeActions {
            Button("Delete", role: .destructive, action: delete)
            Button(reminder.flagged ? "Unflag" : "Flag", action: flag).tint(.orange)
            Button("Details", action: details)
        }
    }

    private var subtitle: Text {
        let due = reminder.due.map { date in
            Text(date.formatted(date: .numeric, time: .shortened))
                .foregroundStyle(reminder.pastDue(at: now) ? .red : .gray)
        } ?? Text("")
        let tags = Text(reminder.sortedTags.map { "#\($0)" }.joined(separator: " ")).foregroundStyle(.gray)
        return Text("\(due)\(reminder.due == nil ? "" : " ")\(tags)").font(.callout)
    }
}
