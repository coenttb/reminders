import ComposableArchitecture2
import Dependencies
import Reminders
import Reminders_Feature
import Reminders_View
import SwiftUI

extension Root {
    /// The pushed detail. It reads the store in its own body so Observation re-renders it on
    /// every change; a value view built inside the `navigationDestination` closure is not
    /// re-evaluated for later changes (the sort menu worked once, then the screen went stale).
    struct Detail: View {
        private var detail: Lists.Detail
        private var store: StoreOf<Lists.Feature>
        @Dependency(\.date.now) private var now

        init(_ detail: Lists.Detail, store: StoreOf<Lists.Feature>) {
            self.detail = detail
            self.store = store
        }

        var body: some View {
            Lists.Detail.View(
                detail,
                lists: store.lists,
                now: now,
                complete: { store.send(.reminderCompleteButtonTapped($0)) },
                flag: { store.send(.reminderFlagButtonTapped($0)) },
                delete: { store.send(.reminderDeleted($0)) },
                details: { store.send(.reminderDetailsButtonTapped($0)) },
                move: { store.send(.remindersMoved($0, $1)) },
                order: { store.send(.orderingSelected($0)) },
                toggleCompleted: { store.send(.showCompletedButtonTapped) },
                newReminder: { store.send(.newReminderButtonTapped) }
            )
        }
    }
}
