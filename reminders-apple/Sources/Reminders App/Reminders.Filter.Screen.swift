import ComposableArchitecture2
import Dependencies
import Organizing
import Reminders
import Reminders_Interface
import Reminders_SQL
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
        let detail = store.detail ?? Reminders.Filter.Detail.Contents(filter: filter, preference: .default(for: filter))
        Reminders.Filter.Detail.View(
            detail,
            title: filter.title ?? list?.title ?? "",
            tint: filter.color(list: list.map { Organizing.Color($0.color) }),
            color: { store.overview.list($0).map { SwiftUI.Color(Organizing.Color($0.color)) } ?? .blue },
            editing: store.editing?.id,
            now: now,
            calendar: calendar,
            draft: { Binding($store[dynamicMember: \.[draft: $0]]) },
            rows: rows,
            editor: editor,
            done: { store.send(.doneButtonTapped) },
            backgroundTapped: { store.send(.backgroundTapped) },
            move: { store.send(.remindersMoved($0, $1)) },
            order: { store.send(.orderingSelected($0)) },
            toggleCompleted: { store.send(.showCompletedButtonTapped) },
            newReminder: { store.send(.newReminderButtonTapped) },
            endReached: { store.send(.detailEndReached) },
            info: list.map { list in { store.send(.listDetailsButtonTapped(list.id)) } },
            delete: list.map { list in { store.send(.listDeleted(list.id)) } },
            clearCompleted: { store.send(.clearCompletedButtonTapped) }
        )
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, store.editing != nil { store.send(.doneButtonTapped) }
        }
    }
}

extension Reminders.Filter.Screen {
    private var list: Organizing.List<Reminder>.Record? {
        if case let .list(id) = filter { store.overview.list(id) } else { nil }
    }

    private var rows: Reminder.Row.Actions {
        Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) },
            edit: { store.send(.reminderTapped($0)) }
        )
    }

    private var editor: Reminder.Editor.Actions {
        Reminder.Editor.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) },
            submit: { store.send(.titleSubmitted) },
            setDate: { store.send(.datePresetSelected($0, $1)) },
            setTime: { store.send(.timePresetSelected($0, $1)) }
        )
    }
}
