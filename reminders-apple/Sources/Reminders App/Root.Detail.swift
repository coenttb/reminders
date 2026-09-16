import ComposableArchitecture2
import Dependencies
import Organizing
import Reminders
import Reminders_Application
import Reminders_Feature
import Reminders_View
import SwiftUI
import Tagged

extension Root {
    struct Detail {
        private var filter: Reminder.Filter
        private var store: StoreOf<Reminder.Feature>
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.scenePhase) private var scenePhase

        init(_ filter: Reminder.Filter, store: StoreOf<Reminder.Feature>) {
            self.filter = filter
            self.store = store
        }
    }
}

extension Root.Detail: SwiftUI::View {
    @ViewBuilder var body: some SwiftUI::View {
        @Bindable var store = store
        let detail = store.detail ?? Reminder.Filter.Detail(filter: filter, preference: filter.defaultPreference)
        Reminder.Filter.Detail.View(
            detail,
            title: filter.title ?? list?.title ?? "",
            editing: store.editing?.id,
            now: now,
            calendar: calendar,
            draft: { $store[dynamicMember: \.[draft: $0]] },
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

extension Root.Detail {
    private var list: Organizing.List<Reminder>? {
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
