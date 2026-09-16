# Reminders View

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## reminders-apple/Sources/Reminders View/Color+SwiftUI.swift

- `public var swiftUI: SwiftUI.Color` — The domain color as SwiftUI draws it; settable, so a picker binds to it through a key path (`$list.color.swiftUI`) and SwiftUI keeps the transaction.
- `public init(_ color: SwiftUI.Color)` — From a picked SwiftUI color, resolved in the default environment.
- `public func color(list: Organizing.Color?) -> SwiftUI.Color` — The accent of a filter: its list's color, or the smart group's.

## reminders-apple/Sources/Reminders View/List.Form.swift

- `public struct Form: SwiftUI.View` — The sheet that creates or edits a list: the badge preview, the name in the list's color, and a palette of colors. Done is disabled until the name has text; dismissing an edited draft asks first.
- `public static var palette: [(name: String, color: Organizing.Color)]` — The seven colors iOS 27 Reminders offers.
- `Section` — Stock (Evidence/Parity/list-info): seven flat 40 pt circles, six to a row, the current one ringed in gray with a gap; no custom color row.
- `public var discardTitle: String` — The question the sheet asks before an edited draft is discarded.

## reminders-apple/Sources/Reminders View/List.Row.swift

- `public struct Row: SwiftUI.View` — One list on the home screen: its colored badge, title, and open count; info and delete are swipe actions.
- `HStack(spacing: 16)` — Stock geometry: 62 pt rows, the badge 16 pt from the title, the count 10 pt from a body-size chevron.
- `Button("Info", systemImage: "info.circle", action: details)` — Edit mode swaps the count for the stock (i) button.
- `public struct Badge: SwiftUI.View` — The circular list glyph in the list's color, sized for a row or a form preview.
- `public struct AddGlyph: SwiftUI.View` — The Add List bar glyph as iOS 27 draws it: a bulleted page with a plus badge bottom-trailing. No SF Symbol carries that badge, so the page and the badge are composed.

## reminders-apple/Sources/Reminders View/Reminder+Titles.swift

- `extension Reminder` — The names the screens show for the domain's values live here, not in the domain: a platform that words them differently maps the same values.
- `public var tagLine: String { tags.sorted().map(Tag<Reminder>.hashtag).joined(separator: " ") }` — The tags as one line of hashtags, in a stable order; empty for none.
- `public var marks: String { String(repeating: "!", count: rawValue) }` — The exclamation marks a row shows before the title.
- `public var title: String` — The name the sort menu shows, in the stock menu's order.
- `public var title: String?` — The name a filter shows; a list's is its title, read with the rest of its detail.
- `public var title: String` — The name the debug seed menu shows, with the reminder count.

## reminders-apple/Sources/Reminders View/Reminder.Due+Description.swift

- `public static func description(of due: Self, at now: Date, calendar: Calendar) -> String` — The due date as iOS 27 Reminders words it: Today, Tomorrow, Yesterday, a weekday within the week, otherwise a short date; the time follows when it matters. Relative to the given now, not the wall clock, so the wording is testable and stable.
- `public static func dayDescription(of due: Self, at now: Date, calendar: Calendar) -> String` — The day alone, for the Date row's subtitle.
- `public static func timeDescription(of due: Self, calendar: Calendar) -> String?` — The time alone, for the Time row's subtitle; none for a day.
- `static func style(date: Date.FormatStyle.DateStyle? = nil, time: Date.FormatStyle.TimeStyle? = nil, calendar: Calendar) -> Date.FormatStyle` — Every date the app words is worded by the app's calendar, not the process's.
- `public func description(on day: Date, calendar: Calendar) -> String?` — The time the preset sets on a day, worded as every other time in the app: from the date the tap would produce, so the menu and the row agree in every locale.

## reminders-apple/Sources/Reminders View/Reminder.Editor.swift

- `public enum Focus: Hashable, Sendable` — Which field of the row being edited holds the keyboard.
- `public struct Editor: SwiftUI.View` — One reminder edited in place, as iOS 27 does it: a raised card with the circle, the title, the note, the Details button, and a row of chips whose menus offer the stock presets. Typing edits the draft through the binding; the chips, Return in the title, the circle, and Details are intents the caller decides.
- `public struct Actions` — What the card asks of its owner, keyed by the reminder. The Date and Time chips are intents because they run calendar rules on the owner's clock, not the view's.
- `VStack(alignment: .leading, spacing: 4)` — Stock card (Evidence/Parity/inline-edit): 107 pt tall, the circle centred 29 pt from the screen edge, the note 22 pt under the title, the chips 26 pt under the note.
- `.background(` — The card is the content's own background, not the row's: a row background is clipped to the row, which cut the shadow and the corners.
- `.onChange(of: focus.wrappedValue) { _, focus in` — Moving on to the note with no title names the reminder, as the stock app does.
- `let date = preset.date(at: now, calendar: calendar)` — Each preset shows its day on a calendar page, as the stock menu does.
- `@ViewBuilder private func checked(_ title: String, _ on: Bool) -> some SwiftUI.View` — A menu item with a checkmark when it is the current value.
- `private func chip(tinted: Bool, @ViewBuilder _ content: () -> some SwiftUI.View) -> some SwiftUI.View` — A chip's face: a gray circle when unset, a tinted capsule naming the value when set. The styling is part of the menu's label, so the menu grows out of the whole chip.

## reminders-apple/Sources/Reminders View/Reminder.Filter.Detail.View.swift

- `public struct View: SwiftUI.View` — The pushed screen for one filter: its colored title, the reminders it shows with one of them possibly edited in place, the sort and show-completed menu, and New Reminder for a list. While a row is edited the menu gives way to Done and the plus hides, as in iOS 27.
- `Text(editMode.isEditing ? "Select Reminders" : title)` — Select mode renames the screen, as stock does (Evidence/Parity/edit-mode).
- `.frame(height: 48)` — The first row starts 106 pt under the safe area, as the stock large title leaves it.
- `if preference.showCompleted, let clearCompleted` — With completed shown, stock heads the list with "N Completed • Clear" over a rule.
- `let (shown, total) = (detail.rows.count, detail.total)` — Stock rows: no separators, 10 pt above and below the text, 42 pt for a title alone. The rows are the first of the filter's; one near the end coming on screen asks for the next, so the list scrolls on without a seam.
- `SwiftUI.Color.clear` — The empty part of a list: a tap there ends editing, or starts a new row.
- `.listRowBackground(SwiftUI.Color.clear)` — Transparent, so the shadow of a card in the last row is not covered.
- `.animation(.default, value: detail.ids)` — Rows animate when they appear, leave, or move; a keystroke in the edited row does not.
- `.onChange(of: editing, initial: true) { _, editing in` — The row being edited takes the keyboard and comes up above it. A new row is read back from the database a moment after it starts — longer in a long list — so the focus is set once the row is among the rows, not after a fixed wait.
- `if !editMode.isEditing` — The stock More menu (Evidence/Parity/list-menu): Show List Info, Select Reminders, Sort By with the current ordering as its subtitle and no item glyphs, Show/Hide Completed, Delete List. Print is out of scope.
- `Menu` — Choosing an ordering is an intent the feature writes, not state the view owns, so the items are buttons with the checkmark on the current one (as the chips do).
- `.overlay` — Stock centres "No Reminders" in an empty list (Evidence/Parity/empty).
- `private func focusEditing(_ proxy: ScrollViewProxy)` — Scrolls the edited row into view once it exists, then focuses its title. The row is focused after the scroll: a List row far down a long list has no field to focus until it has been brought on screen, and a focus set before that is dropped.
- `private var rowActions: Reminder.Row.Actions` — Rows edit in place only inside a list; elsewhere a tap opens details.

## reminders-apple/Sources/Reminders View/Reminder.Filter.Tile.swift

- `public struct Tile: SwiftUI.View` — One tile of the home grid, as iOS 27 draws it: 80 pt tall, a vertical gradient in the filter's color, the white glyph top-leading, the count top-trailing in rounded bold, the filter's name bottom-leading. Measured on the stock app (Evidence/Parity/home): tiles 181×80 with 8 pt gaps, radius 18.
- `public struct Fill: Hashable, Sendable` — The stock tile gradients, sampled top and bottom (sRGB 0–255) on the iOS 27 simulator.
- `public enum Glyph: Hashable, Sendable` — A tile's glyph: a symbol, or the calendar page showing today's day as the stock Today tile does.
- `Image(systemName: "\(day).calendar").font(.system(size: 24, weight: .medium))` — SF Symbols 7 ships the stock glyph: a calendar page with the day inside.
- `public static func smart(flagged: Bool) -> [Reminder.Filter]` — The smart groups in the home's order; Flagged only while something is flagged.
- `@ViewBuilder public static func badge(for filter: Reminder.Filter, day: Int) -> some SwiftUI.View` — The 32 pt circle the home's edit mode shows for a smart group: its glyph on its color.

## reminders-apple/Sources/Reminders View/Reminder.Form.swift

- `public struct Form: SwiftUI.View` — The sheet that creates or edits a reminder, as iOS 27's: title and notes in one card, Date and Time as a coupled pair, then List and the pushed Details (or, when editing, the organisation rows inline). The draft is edited through the binding; save and cancel are the caller's. Done needs a title, and an edited draft asks before it is discarded.
- `private enum Expansion { case date, time }` — Which of the two pickers is open under its row; only one at a time.
- `.listSectionMargins(.top, 6)` — The stock card sits 22 pt under the bar, not at the form's default.
- `Section("Organisation") { listPicker }` — Stock groups: Organisation holds List and Priority as separate cards, then Tags and Flag; Location is under Places & People (Evidence/Parity/details-sheet).
- `.safeAreaBar(edge: .bottom)` — A keyboard-placed toolbar never appears inside this sheet, so the quick bar is a bottom bar shown while a field has the keyboard.
- `.onChange(of: reminder.due != nil) { _, on in` — Turning a row on opens its picker and drops the keyboard; turning it off closes the picker. The toggles bind through key paths, so the view effects live here rather than in a binding's setter.
- `private var quickBar: some SwiftUI.View` — The quick bar above the keyboard, as stock: Date & Time, Location, Flag, Photos (Evidence/Parity/new-reminder-sheet). Photos is out of scope and stays disabled.
- `public var discardTitle: String` — The question the sheet asks before an edited draft is discarded.
- `private func row(_ title: String, systemImage: String, subtitle: String?, tap: @escaping () -> Void) -> some SwiftUI.View` — A toggle label with the gray outline glyph and, once set, the blue subtitle; tapping the text opens the picker under the row.
- `private var listPicker: some SwiftUI.View` — The List row names the list after the badge, as the stock row does; the pushed screen lists every list with its badge and a checkmark on the current one.
- `fileprivate subscript(dueOn now: Date, calendar calendar: Calendar) -> Bool` — The Date row: on means due today, off clears the date and the time with it.
- `fileprivate subscript(timeOn now: Date, calendar calendar: Calendar) -> Bool` — The Time row: on proposes the next full hour and turns the date on with it.
- `fileprivate subscript(date fallback: Date) -> Date` — The pickers edit the due date's moment, keeping whether the time matters.
- `fileprivate func dueOn(_ now: Date, calendar: Calendar) -> Binding<Bool> { self[dynamicMember: \.[dueOn: now, calendar: calendar]] }` — The toggles and pickers as key-path projections of the draft, so SwiftUI keeps their transaction.

## reminders-apple/Sources/Reminders View/Reminder.Overview.View.swift

- `public struct View: SwiftUI.View` — The home sections inside the app's list: the smart-group tiles, the user's lists, and the tags in use. Every tap is a callback; the value is read-only.
- `ForEach(Reminder.Filter.smart(flagged: counts.flagged > 0), id: \.self) { filter in` — Edit mode lists the smart groups as rows with grips, as stock does (Evidence/Parity/edit-mode); stock's visibility toggles are not modelled.
- `LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8)` — Flagged appears only while something is flagged, as in iOS 27.
- `.listSectionMargins(.top, 0)` — The grid sits 16 pt under the bar, where the stock app puts it, not at the inset-grouped default.
- `Text(title)` — `.primary` inside a header resolves against the header's secondary style; the color itself keeps the stock black.

## reminders-apple/Sources/Reminders View/Reminder.Row.swift

- `public struct Row: SwiftUI.View` — One reminder at rest in a detail or search: the completion circle, the title with priority marks and flag, and one gray line of due date, notes, and tags. Tapping the text edits the row in place where the caller offers it, otherwise opens details; Details and Delete are the swipe actions, as in iOS 27.
- `public struct Actions` — What a row asks of its owner, keyed by the reminder; `edit` only where rows edit in place.
- `.frame(width: 26, height: 20)` — The circle overhangs the text line, as the stock 44 pt button does; a title-only row stays 42 pt.
- `VStack(alignment: .leading, spacing: 4)` — Stock: the gray line sits 24 pt under the title's top.

## reminders-apple/Sources/Reminders View/Reminder.Search.View.swift

- `public struct View: SwiftUI.View` — The sections shown while searching: tag completions, the completed summary with its clear menu, and the matches grouped under their lists.
- `let completed = results.completedCount` — A reminder in its grace period is neither counted nor hidden, so the tap can be undone.
- `Section` — Stock (Evidence/Parity/search): a plain white page, the header at x 16, list names as title2 headers in their color, 40 pt rows without separators.
- `let (shown, total) = (results.shown, results.total)` — The matches are the first of the search's; one near the end coming on screen asks for the next. Sections count from the start so the index runs across them.

## reminders-apple/Sources/Reminders View/Tag+Hashtag.swift

- `public static func hashtag(_ id: ID) -> String { "#\(id.rawValue)" }` — How a tag is shown wherever it is named: its title behind a hash.

## reminders-apple/Sources/Reminders View/Tag.Picker.swift

- `public struct Picker: SwiftUI.View` — Chooses tags for a reminder: the known tags with the most used first, and new, rename, and delete, which are the caller's to apply.

## reminders-apple/Sources/Reminders View/Tag.Row.swift

- `public struct Cloud: SwiftUI.View` — The home's Tags card as iOS 27 draws it: one card of capsules that wrap, "All Tags" first, then each tag as its hashtag. A tap opens the tag; a long press offers Delete.
- `public struct Pill: SwiftUI.View` — One capsule of the cloud: body text on a gray fill.
- `struct Flow: Layout` — Lays subviews out left to right, wrapping to a new line when the width runs out.

## reminders-apple/Sources/Reminders View/View+DiscardPrompt.swift

- `public func discardPrompt(_ title: String, isPresented: Binding<Bool>, discard: @escaping () -> Void) -> some View` — The question a sheet asks before an edited draft is thrown away, as a popover growing out of the button it is attached to: the question, then one destructive Discard Changes; tapping elsewhere keeps editing.
