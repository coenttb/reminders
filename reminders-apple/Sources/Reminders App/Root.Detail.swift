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
    /// The pushed detail. It reads the store in its own body so Observation re-renders it on
    /// every change; a value view built inside the `navigationDestination` closure is not
    /// re-evaluated for later changes (the sort menu worked once, then the screen went stale).
    struct Detail: View {
        private var filter: Reminder.Filter
        private var store: StoreOf<Reminder.Feature>
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.scenePhase) private var scenePhase

        init(_ filter: Reminder.Filter, store: StoreOf<Reminder.Feature>) {
            self.filter = filter
            self.store = store
        }

        var body: some View {
            @Bindable var store = store
            // The detail is read a moment after the filter opens; until then the screen is empty.
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
                info: list.map { list in { store.send(.listDetailsButtonTapped(list.id)) } },
                delete: list.map { list in { store.send(.listDeleted(list.id)) } },
                clearCompleted: { store.send(.clearCompletedButtonTapped) }
            )
            // Leaving the app commits the row being edited, as the stock app does.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background, store.editing != nil { store.send(.doneButtonTapped) }
            }
        }
    }
}

extension Root.Detail {
    /// The list a list filter shows, named by the overview.
    private var list: Organizing.List<Reminder>? {
        if case let .list(id) = filter { store.overview.list(id) } else { nil }
    }

    /// A detail's rows edit in place on a tap.
    private var rows: Reminder.Row.Actions {
        Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) },
            edit: { store.send(.reminderTapped($0)) }
        )
    }

    /// The card's intents, each one action; the chips run on the feature's clock.
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
