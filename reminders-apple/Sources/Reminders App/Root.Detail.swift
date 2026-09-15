import ComposableArchitecture2
import Foundation
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
                lists: store.lists,
                now: now,
                draft: { $store.lists.draft($0) },
                edit: { store.send(.reminderTapped($0)) },
                submit: { store.send(.titleSubmitted) },
                done: { store.send(.doneButtonTapped) },
                backgroundTapped: { store.send(.backgroundTapped) },
                complete: { store.send(.reminderCompleteButtonTapped($0)) },
                flag: { store.send(.reminderFlagButtonTapped($0)) },
                delete: { store.send(.reminderDeleted($0)) },
                details: { store.send(.reminderDetailsButtonTapped($0)) },
                move: { store.send(.remindersMoved($0, $1)) },
                order: { store.send(.orderingSelected($0)) },
                toggleCompleted: { store.send(.showCompletedButtonTapped) },
                newReminder: { store.send(.newReminderButtonTapped) }
            )
            // Leaving the app commits the row being edited, as the stock app does.
            .onChange(of: scenePhase) { _, phase in
                if phase != .active, store.lists.editing != nil { store.send(.doneButtonTapped) }
            }
        }
    }
}

extension Binding<Lists> {
    /// The row's draft as a key-path projection of the lists, so the editor's fields
    /// keep SwiftUI's transaction and every write is one state edit.
    fileprivate func draft(_ id: Reminder.ID) -> Binding<Reminder> { self[dynamicMember: \.[draft: id]] }
}
