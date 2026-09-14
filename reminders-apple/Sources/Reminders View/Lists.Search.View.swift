public import Foundation
public import Reminders
public import SwiftUI
public import Tagged

extension Lists.Search {
    /// The sections shown while searching: tag completions, the completed
    /// summary with its clear menu, and the matches grouped under their lists.
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
        let shown = search.showCompleted ? matches : matches.filter { !$0.completed }
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
        ForEach(lists.orderedLists) { list in
            let rows = shown.filter { $0.list == list.id }
            if !rows.isEmpty {
                Section {
                    ForEach(rows) { reminder in
                        Reminder.Row(
                            reminder,
                            color: list.color.swiftUI,
                            now: now,
                            complete: { complete(reminder.id) },
                            flag: { flag(reminder.id) },
                            delete: { delete(reminder.id) },
                            details: { details(reminder.id) }
                        )
                    }
                } header: {
                    Text(list.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(list.color.swiftUI)
                        .textCase(nil)
                        .padding(.leading, -4)
                }
                .listRowBackground(Color.clear)
            }
        }
    }
}
