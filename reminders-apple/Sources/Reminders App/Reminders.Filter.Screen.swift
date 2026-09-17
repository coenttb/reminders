import ComposableArchitecture2
import Dependencies
import Models
import Reminder
import Reminders
import Reminders_Feature
import Reminders_View
import SwiftUI
import Tagged

extension Reminders.Filter {
    struct Screen {
        private var filter: Reminders.Filter
        private var store: StoreOf<Reminders.Feature>
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.scenePhase) private var scenePhase

        init(_ filter: Reminders.Filter, store: StoreOf<Reminders.Feature>) {
            self.filter = filter
            self.store = store
        }
    }
}

extension Reminders.Filter.Screen: SwiftUI::View {
    @ViewBuilder var body: some SwiftUI::View {
        @Bindable var store = store
        let contents = store.detail ?? Reminders.List.Result(selection: .filter(filter), preference: .default(for: filter))
        let style = Reminders.Filter.Style(filter, list: list, day: calendar.component(.day, from: now))
        Reminders.Listing.View.SwiftUI(
            contents: contents,
            style: style,
            color: { store.overview.list($0).map { SwiftUI.Color($0.color) } ?? .blue },
            draft: { Binding($store[dynamicMember: \.[draft: $0]]) },
            view: Reminders.Listing.View(
                filter: filter,
                window: store.detailWindow,
                editing: store.editing?.id,
                grace: store.gracing,
                now: now,
                calendar: calendar,
                actions: actions
            )
        )
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, store.editing != nil { store.send(.doneButtonTapped) }
        }
    }
}

extension Reminders.Filter.Screen {
    private var listID: Models.List<Reminder>.ID? {
        if case let .list(id) = filter { id } else { nil }
    }

    private var list: Models.List<Reminder>? { listID.flatMap(store.overview.list) }

    private var actions: Reminders.Listing.View.Actions {
        Reminders.Listing.View.Actions(
            rows: Reminder.Row.Actions(
                complete: { store.send(.reminderCompleteButtonTapped($0)) },
                delete: { store.send(.reminderDeleted($0)) },
                details: { store.send(.reminderDetailsButtonTapped($0)) },
                edit: listID.map { _ in { store.send(.reminderTapped($0)) } }
            ),
            editor: Reminder.Editor.Actions(
                complete: { store.send(.reminderCompleteButtonTapped($0)) },
                details: { store.send(.reminderDetailsButtonTapped($0)) },
                submit: { store.send(.titleSubmitted) },
                setDate: { store.send(.datePresetSelected($0, $1)) },
                setTime: { store.send(.timePresetSelected($0, $1)) }
            ),
            done: { store.send(.doneButtonTapped) },
            backgroundTapped: { store.send(.backgroundTapped) },
            toggleCompleted: { store.send(.showCompletedButtonTapped) },
            endReached: { store.send(.detailEndReached) },
            move: { store.send(.remindersMoved($0, $1)) },
            order: { store.send(.orderingSelected($0)) },
            newReminder: listID.map { _ in { store.send(.newReminderButtonTapped) } },
            info: listID.map { id in { store.send(.listDetailsButtonTapped(id)) } },
            delete: listID.map { id in { store.send(.listDeleted(id)) } },
            clearCompleted: { store.send(.clearCompletedButtonTapped) }
        )
    }
}
