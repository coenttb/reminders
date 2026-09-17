public import ComposableArchitecture2
import Dependencies
import Models
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
import Tagged

extension Reminders.Search {
    public struct SwiftUI {
        private var store: StoreOf<Reminders.Search.Feature>
        private var contents: Reminders.Search.Contents
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar

        public init(store: StoreOf<Reminders.Search.Feature>, contents: Reminders.Search.Contents) {
            self.store = store
            self.contents = contents
        }
    }
}

extension Reminders.Search.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let suggestions = contents.suggestions
        let completed = contents.completedCount
        if !suggestions.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions) { tag in
                            Button(tag.hashtag) { store.send(.tagTapped(tag)) }.buttonStyle(.glass)
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
                    Button("Older Than 1 Month") { store.send(.deleteCompletedButtonTapped(olderThanMonths: 1)) }
                    Button("Older Than 6 Months") { store.send(.deleteCompletedButtonTapped(olderThanMonths: 6)) }
                    Button("Older Than 1 Year") { store.send(.deleteCompletedButtonTapped(olderThanMonths: 12)) }
                    Button("All Completed") { store.send(.deleteCompletedButtonTapped(olderThanMonths: nil)) }
                }
                .disabled(completed == 0)
                Spacer()
                Button(store.field.showCompleted ? "Hide" : "Show") { store.send(.completedButtonTapped) }.disabled(completed == 0)
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
        let actions = Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) }
        )
        ForEach(Array(contents.sections.enumerated()), id: \.element.id) { position, section in
            Section {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { offset, reminder in
                    Reminder.Row.SwiftUI(reminder: reminder, completed: store.state.isShownCompleted(reminder), color: SwiftUI::Color(section.list.color), now: now, calendar: calendar, actions: actions)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if store.window.nearsEnd(starts[position] + offset, of: shown, total: total) { store.send(.endReached) } }
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
