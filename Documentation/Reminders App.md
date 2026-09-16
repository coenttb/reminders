# Reminders App

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## reminders-apple/Sources/Reminders App/Reminder.Feature+Live.swift

- `public static func live() -> StoreOf<Reminder.Feature>` — Bootstraps the application's database and returns the store the host owns.

## reminders-apple/Sources/Reminders App/Root.Detail.swift

- `struct Detail: View` — The pushed detail. It reads the store in its own body so Observation re-renders it on every change; a value view built inside the `navigationDestination` closure is not re-evaluated for later changes (the sort menu worked once, then the screen went stale).
- `let detail = store.detail ?? Reminder.Filter.Detail(filter: filter, preference: filter.defaultPreference)` — The detail is read a moment after the filter opens; until then the screen is empty.
- `.onChange(of: scenePhase) { _, phase in` — Leaving the app commits the row being edited, as the stock app does.
- `private var list: Organizing.List<Reminder>?` — The list a list filter shows, named by the overview.
- `private var rows: Reminder.Row.Actions` — A detail's rows edit in place on a tap.
- `private var editor: Reminder.Editor.Actions` — The card's intents, each one action; the chips run on the feature's clock.

## reminders-apple/Sources/Reminders App/Root.swift

- `public struct Root: View` — The application composes the home, search, the pushed detail, and the two form sheets from its store; navigation is feature state. The chrome follows iOS 27 Reminders: no home title, glass pills top-trailing, the search field and New Reminder in the bottom bar, sheets with glyph buttons.
- `.scrollContentBackground(store.search.isActive ? .hidden : .visible)` — Search results sit on a plain white page, as stock draws them.
- `ToolbarItem(placement: .topBarTrailing)` — The seed menu: the reference fixture, three deterministic scales, the same scales on a fresh seed, a replay of the last seed, and an empty database.
- `ToolbarItem(placement: .topBarTrailing)` — Stock: "Edit" as text, Done as the prominent checkmark (Evidence/Parity/edit-mode).
- `.searchable(text: $store.search.text, tokens: $store.search.tokens) { token in` — Search is declared on the stack, not on the list inside it, as in the iOS 26 samples: declared on the content, SwiftUI vends the field from a second navigation item and cancelling evicts the list's rows behind the keyboard. The field lives in the bottom bar and minimizes to a pill; the system owns its keyboard attachment and, on iPhone Duo, its bar placement.
- `.interactiveDismissDisabled(form.isDirty)` — An edited draft cannot be swiped away; the form's X asks before discarding. SwiftUI has no hook on the drag itself (dismissalConfirmationDialog wraps the dismiss action, not the gesture), and UIKit bridges are out.
- `.presentationDetents(form.isNew ? [.large] : [.fraction(0.715), .large])` — Stock opens Details at the height of its content (624 of 874 pt on the iPhone 17) and grows to full height on a drag; New Reminder is full height.
- `.onChange(of: scenePhase) { _, phase in` — Coming back to the foreground may be coming back on another day.
- `.alert("Something went wrong", isPresented: $store.failure.isPresent)` — Dismissing the alert clears the failure through the binding's key path.
