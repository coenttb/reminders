public import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Lists.Search {
    /// The sections shown while searching: tag completions, the completed
    /// summary with its clear menu, and the matching reminders.
    public struct View: SwiftUI.View {
        private var search: Lists.Search
        private var lists: Lists
        private var now: Date
        private var addTag: (Tag.ID) -> Void
        private var toggleCompleted: () -> Void
        private var deleteCompleted: (Int?) -> Void
        private var complete: (Reminder.ID) -> Void
        private var flag: (Reminder.ID) -> Void
        private var delete: (Reminder.ID) -> Void
        private var details: (Reminder.ID) -> Void

        public init(
            _ search: Lists.Search,
            lists: Lists,
            now: Date,
            addTag: @escaping (Tag.ID) -> Void,
            toggleCompleted: @escaping () -> Void,
            deleteCompleted: @escaping (Int?) -> Void,
            complete: @escaping (Reminder.ID) -> Void,
            flag: @escaping (Reminder.ID) -> Void,
            delete: @escaping (Reminder.ID) -> Void,
            details: @escaping (Reminder.ID) -> Void
        ) {
            self.search = search
            self.lists = lists
            self.now = now
            self.addTag = addTag
            self.toggleCompleted = toggleCompleted
            self.deleteCompleted = deleteCompleted
            self.complete = complete
            self.flag = flag
            self.delete = delete
            self.details = details
        }
    }
}

extension Lists.Search.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let suggestions = lists.tagSuggestions(for: search)
        let matches = lists.matches(search)
        let completed = matches.filter(\.completed).count
        if !suggestions.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions) { tag in
                            Button("#\(tag.title)") { addTag(tag.id) }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        HStack {
            Text("\(completed) Completed").monospacedDigit().contentTransition(.numericText())
            if completed > 0 {
                Text("•")
                Menu {
                    Text("Clear Completed Reminders")
                    Button("Older Than 1 Month") { deleteCompleted(1) }
                    Button("Older Than 6 Months") { deleteCompleted(6) }
                    Button("Older Than 1 Year") { deleteCompleted(12) }
                    Button("All Completed") { deleteCompleted(nil) }
                } label: {
                    Text("Clear")
                }
                Spacer()
                Button(search.showCompleted ? "Hide" : "Show", action: toggleCompleted)
            }
        }
        .buttonStyle(.borderless)
        ForEach(search.showCompleted ? matches : matches.filter { !$0.completed }) { reminder in
            Reminder.Row(
                reminder,
                color: lists.list(reminder.list)?.color.swiftUI ?? .blue,
                now: now,
                complete: { complete(reminder.id) },
                flag: { flag(reminder.id) },
                delete: { delete(reminder.id) },
                details: { details(reminder.id) }
            )
        }
    }
}
