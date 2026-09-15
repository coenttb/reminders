import ComposableArchitecture2
import Dependencies
import Reminders
import Reminders_Feature
import Reminders_View
import SwiftUI
import Tagged

extension Root {
    /// The pushed detail. It reads the store in its own body so Observation re-renders it on
    /// every change; a value view built inside the `navigationDestination` closure is not
    /// re-evaluated for later changes (the sort menu worked once, then the screen went stale).
    struct Detail: View {
        private var detail: Lists.Detail
        private var store: StoreOf<Lists.Feature>
        @Dependency(\.date.now) private var now
        @Environment(\.scenePhase) private var scenePhase

        init(_ detail: Lists.Detail, store: StoreOf<Lists.Feature>) {
            self.detail = detail
            self.store = store
        }

        var body: some View {
            @Bindable var store = store
            Lists.Detail.View(
                detail,
                contents: store.contents,
                editing: store.editing?.id,
                now: now,
                draft: { $store[dynamicMember: \.[draft: $0]] },
                rows: rows,
                editor: editor,
                done: { store.send(.doneButtonTapped) },
                backgroundTapped: { store.send(.backgroundTapped) },
                move: { store.send(.remindersMoved($0, $1)) },
                order: { store.send(.orderingSelected($0)) },
                toggleCompleted: { store.send(.showCompletedButtonTapped) },
                newReminder: { store.send(.newReminderButtonTapped) }
            )
            // Leaving the app commits the row being edited, as the stock app does.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background, store.editing != nil { store.send(.doneButtonTapped) }
            }
        }
    }
}

extension Root.Detail {
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
