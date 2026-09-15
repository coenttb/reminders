public import Foundation
public import Reminders
public import SwiftUI

extension Lists.Detail {
    /// The pushed screen for one detail: its colored title, the reminders it
    /// shows with one of them possibly edited in place, the sort and
    /// show-completed menu, and New Reminder for a list. While a row is edited
    /// the menu gives way to Done and the plus hides, as in iOS 27.
    public struct View: SwiftUI.View {
        private var detail: Lists.Detail
        private var lists: Lists
        private var now: Date
        private var draft: (Reminder.ID) -> Binding<Reminder>
        private var edit: (Reminder.ID) -> Void
        private var submit: () -> Void
        private var done: () -> Void
        private var backgroundTapped: () -> Void
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
        @FocusState private var focus: Reminder.Focus?

        public init(
            _ detail: Lists.Detail,
            lists: Lists,
            now: Date,
            draft: @escaping (Reminder.ID) -> Binding<Reminder>,
            edit: @escaping (Reminder.ID) -> Void,
            submit: @escaping () -> Void,
            done: @escaping () -> Void,
            backgroundTapped: @escaping () -> Void,
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
            self.draft = draft
            self.edit = edit
            self.submit = submit
            self.done = done
            self.backgroundTapped = backgroundTapped
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
        ScrollViewReader { proxy in
        List {
            GeometryReader { proxy in
                Text(lists.title(of: detail))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(color)
                    .onAppear { titleHeight = proxy.size.height }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            ForEach(lists.reminders(in: detail, at: now)) { reminder in
                if reminder.id == lists.editing {
                    Reminder.Editor(
                        reminder: draft(reminder.id),
                        color: lists.list(reminder.list)?.color.swiftUI ?? color,
                        now: now,
                        focus: $focus,
                        complete: { complete(reminder.id) },
                        submit: submit,
                        details: { details(reminder.id) }
                    )
                } else {
                    Reminder.Row(
                        reminder,
                        color: lists.list(reminder.list)?.color.swiftUI ?? color,
                        now: now,
                        complete: { complete(reminder.id) },
                        flag: { flag(reminder.id) },
                        delete: { delete(reminder.id) },
                        details: { details(reminder.id) },
                        edit: detail.isList ? { edit(reminder.id) } : nil
                    )
                }
            }
            .onMove(perform: move)
            // The empty part of a list: a tap there ends editing, or starts a new row.
            Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture(perform: backgroundTapped)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                // Transparent, so the shadow of a card in the last row is not covered.
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .animation(.default, value: lists)
        .onChange(of: lists.editing, initial: true) { _, editing in
            focus = editing.map(Reminder.Focus.title)
            // The row being edited comes up above the keyboard.
            if let editing {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(80))
                    withAnimation { proxy.scrollTo(editing, anchor: .center) }
                }
            }
        }
        }
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
            if detail.isList, lists.editing == nil {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus", action: newReminder)
                        .buttonStyle(.glassProminent)
                        .tint(color)
                }
                .visibilityPriority(.high)
            }
            if lists.editing != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", action: done)
                        .buttonStyle(.glassProminent)
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
                    Label("More", systemImage: "ellipsis")
                }
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
