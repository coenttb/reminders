public import Foundation
public import Reminders
public import SwiftUI

extension Lists.Detail {
    /// The pushed screen for one detail: its colored title, the reminders it
    /// shows, the sort and show-completed menu, and New Reminder for a list.
    public struct View: SwiftUI.View {
        private var detail: Lists.Detail
        private var lists: Lists
        private var now: Date
        private var complete: (Reminder.ID) -> Void
        private var flag: (Reminder.ID) -> Void
        private var delete: (Reminder.ID) -> Void
        private var details: (Reminder.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var order: (Lists.Ordering) -> Void
        private var toggleCompleted: () -> Void
        private var newReminder: () -> Void
        @State private var titleVisible = false
        @State private var titleHeight: CGFloat = 36

        public init(
            _ detail: Lists.Detail,
            lists: Lists,
            now: Date,
            complete: @escaping (Reminder.ID) -> Void,
            flag: @escaping (Reminder.ID) -> Void,
            delete: @escaping (Reminder.ID) -> Void,
            details: @escaping (Reminder.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            order: @escaping (Lists.Ordering) -> Void,
            toggleCompleted: @escaping () -> Void,
            newReminder: @escaping () -> Void
        ) {
            self.detail = detail
            self.lists = lists
            self.now = now
            self.complete = complete
            self.flag = flag
            self.delete = delete
            self.details = details
            self.move = move
            self.order = order
            self.toggleCompleted = toggleCompleted
            self.newReminder = newReminder
        }
    }
}

extension Lists.Detail.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let color = detail.color(in: lists)
        let preference = lists.preference(for: detail)
        List {
            GeometryReader { proxy in
                Text(lists.title(of: detail))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
                    .onAppear { titleHeight = proxy.size.height }
            }
            .listRowSeparator(.hidden)
            ForEach(lists.reminders(in: detail, at: now)) { reminder in
                Reminder.Row(
                    reminder,
                    color: lists.list(reminder.list)?.color.swiftUI ?? color,
                    now: now,
                    complete: { complete(reminder.id) },
                    flag: { flag(reminder.id) },
                    delete: { delete(reminder.id) },
                    details: { details(reminder.id) }
                )
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > titleHeight
        } action: { _, visible in
            titleVisible = visible
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(lists.title(of: detail))
                    .font(.headline)
                    .opacity(titleVisible ? 1 : 0)
                    .animation(.default.speed(2), value: titleVisible)
            }
            if detail.isList {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: newReminder) {
                            Label("New Reminder", systemImage: "plus.circle.fill").bold().font(.title3)
                        }
                        Spacer()
                    }
                    .tint(color)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Menu {
                        ForEach(Lists.Ordering.allCases, id: \.self) { ordering in
                            Button { order(ordering) } label: {
                                Text(ordering.rawValue)
                                Image(systemName: ordering.systemImage)
                            }
                        }
                    } label: {
                        Text("Sort By")
                        Text(preference.ordering.rawValue)
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    Button(action: toggleCompleted) {
                        Text(preference.showCompleted ? "Hide Completed" : "Show Completed")
                        Image(systemName: preference.showCompleted ? "eye.slash.fill" : "eye")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(color)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}

extension Lists.Ordering {
    var systemImage: String {
        switch self {
        case .dueDate: "calendar"
        case .manual: "hand.draw"
        case .priority: "chart.bar.fill"
        case .title: "textformat.characters"
        }
    }
}
