import Models
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
import Tagged

extension Reminders.Search.View {
    public struct SwiftUI {
        private var contents: Reminders.Search.Contents
        private var view: Reminders.Search.View

        public init(contents: Reminders.Search.Contents, view: Reminders.Search.View) {
            self.contents = contents
            self.view = view
        }
    }
}

extension Reminders.Search.View.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let suggestions = contents.suggestions
        let completed = contents.completedCount
        let actions = view.actions
        if !suggestions.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions) { tag in
                            Button(tag.hashtag) { actions.addTag(tag) }.buttonStyle(.glass)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.9), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing)
                }
            }
            .listRowBackground(SwiftUI::Color.clear)
            .listRowInsets(EdgeInsets())
        }
        Section {
            HStack {
                Text("\(completed) Completed").monospacedDigit().contentTransition(.numericText()).foregroundStyle(.secondary)
                Text("•").foregroundStyle(.secondary)
                Menu("Clear") {
                    Text("Clear Completed Reminders")
                    Button("Older Than 1 Month") { actions.deleteCompleted(1) }
                    Button("Older Than 6 Months") { actions.deleteCompleted(6) }
                    Button("Older Than 1 Year") { actions.deleteCompleted(12) }
                    Button("All Completed") { actions.deleteCompleted(nil) }
                }
                .disabled(completed == 0)
                Spacer()
                Button(view.showCompleted ? "Hide" : "Show", action: actions.toggleCompleted).disabled(completed == 0)
            }
            .buttonStyle(.borderless)
        }
        .listRowBackground(SwiftUI::Color.clear)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowSeparator(.hidden)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .listRowSeparator(.visible, edges: .bottom)
        .listSectionMargins(.horizontal, 0)
        let (shown, total) = (contents.shown, contents.total)
        let starts = contents.sections.reduce(into: [0]) { $0.append($0[$0.count - 1] + $1.rows.count) }
        let row = Reminder.Row(now: view.now, calendar: view.calendar, actions: actions.rows)
        ForEach(Array(contents.sections.enumerated()), id: \.element.id) { position, section in
            Section {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { offset, reminder in
                    Reminder.Row.SwiftUI(reminder: reminder, completed: reminder.completed || view.grace.contains(reminder.id), color: SwiftUI::Color(section.list.color), view: row)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if view.window.nearsEnd(starts[position] + offset, of: shown, total: total) { actions.endReached() } }
                }
            } header: {
                Text(section.list.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SwiftUI::Color(section.list.color))
                    .textCase(nil)
            }
            .listRowBackground(SwiftUI::Color.clear)
            .listSectionMargins(.horizontal, 0)
        }
    }
}
