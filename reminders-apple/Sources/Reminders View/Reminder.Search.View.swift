public import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SwiftUI
public import Tagged

extension Reminder.Search {
    public struct View: SwiftUI.View {
        private var search: Reminder.Search
        private var results: Reminder.Search.Results
        private var now: Date
        private var calendar: Calendar
        private var rows: Reminder.Row.Actions
        private var addTag: (Tag<Reminder>.ID) -> Void
        private var toggleCompleted: () -> Void
        private var deleteCompleted: (Int?) -> Void
        private var endReached: () -> Void

        public init(
            _ search: Reminder.Search,
            results: Reminder.Search.Results,
            now: Date,
            calendar: Calendar,
            rows: Reminder.Row.Actions,
            addTag: @escaping (Tag<Reminder>.ID) -> Void,
            toggleCompleted: @escaping () -> Void,
            deleteCompleted: @escaping (Int?) -> Void,
            endReached: @escaping () -> Void
        ) {
            self.search = search
            self.results = results
            self.now = now
            self.calendar = calendar
            self.rows = rows
            self.addTag = addTag
            self.toggleCompleted = toggleCompleted
            self.deleteCompleted = deleteCompleted
            self.endReached = endReached
        }
    }
}

extension Reminder.Search.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let suggestions = results.suggestions
        let completed = results.completedCount
        if !suggestions.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions) { tag in
                            Button(tag.hashtag) { addTag(tag.id) }.buttonStyle(.glass)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.9), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing)
                }
            }
            .listRowBackground(SwiftUI.Color.clear)
            .listRowInsets(EdgeInsets())
        }
        Section {
            HStack {
                Text("\(completed) Completed").monospacedDigit().contentTransition(.numericText()).foregroundStyle(.secondary)
                Text("•").foregroundStyle(.secondary)
                Menu("Clear") {
                    Text("Clear Completed Reminders")
                    Button("Older Than 1 Month") { deleteCompleted(1) }
                    Button("Older Than 6 Months") { deleteCompleted(6) }
                    Button("Older Than 1 Year") { deleteCompleted(12) }
                    Button("All Completed") { deleteCompleted(nil) }
                }
                .disabled(completed == 0)
                Spacer()
                Button(search.showCompleted ? "Hide" : "Show", action: toggleCompleted).disabled(completed == 0)
            }
            .buttonStyle(.borderless)
        }
        .listRowBackground(SwiftUI.Color.clear)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowSeparator(.hidden)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .listRowSeparator(.visible, edges: .bottom)
        .listSectionMargins(.horizontal, 0)
        let (shown, total) = (results.shown, results.total)
        let starts = results.sections.reduce(into: [0]) { $0.append($0[$0.count - 1] + $1.reminders.count) }
        ForEach(Array(results.sections.enumerated()), id: \.element.id) { position, section in
            Section {
                ForEach(Array(section.reminders.enumerated()), id: \.element.id) { offset, reminder in
                    Reminder.Row(reminder, color: section.list.color.swiftUI, now: now, calendar: calendar, actions: rows)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if Reminder.Window<Reminder.Search>.nearsEnd(starts[position] + offset, of: shown, total: total) { endReached() } }
                }
            } header: {
                Text(section.list.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(section.list.color.swiftUI)
                    .textCase(nil)
            }
            .listRowBackground(SwiftUI.Color.clear)
            .listSectionMargins(.horizontal, 0)
        }
    }
}
