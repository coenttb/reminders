public import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Lists.Search {
    /// The sections shown while searching: tag completions, the completed
    /// summary with its clear menu, and the matches grouped under their lists.
    public struct View: SwiftUI.View {
        private var search: Lists.Search
        private var results: Lists.Search.Results
        private var now: Date
        private var rows: Reminder.Row.Actions
        private var addTag: (Tag.ID) -> Void
        private var toggleCompleted: () -> Void
        private var deleteCompleted: (Int?) -> Void

        public init(
            _ search: Lists.Search,
            results: Lists.Search.Results,
            now: Date,
            rows: Reminder.Row.Actions,
            addTag: @escaping (Tag.ID) -> Void,
            toggleCompleted: @escaping () -> Void,
            deleteCompleted: @escaping (Int?) -> Void
        ) {
            self.search = search
            self.results = results
            self.now = now
            self.rows = rows
            self.addTag = addTag
            self.toggleCompleted = toggleCompleted
            self.deleteCompleted = deleteCompleted
        }
    }
}

extension Lists.Search.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let suggestions = results.suggestions
        // A reminder in its grace period is neither counted nor hidden, so the tap can be undone.
        let completed = results.completedCount
        if !suggestions.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions) { tag in
                            Button("#\(tag.title)") { addTag(tag.id) }.buttonStyle(.glass)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.9), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing)
                }
            }
            .listRowBackground(Color.clear)
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
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        ForEach(results.sections) { section in
            Section {
                ForEach(section.reminders) { reminder in
                    Reminder.Row(reminder, color: section.list.color.swiftUI, now: now, actions: rows)
                }
            } header: {
                Text(section.list.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(section.list.color.swiftUI)
                    .textCase(nil)
                    .padding(.leading, -4)
            }
            .listRowBackground(Color.clear)
        }
    }
}
