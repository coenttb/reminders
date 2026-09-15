# Parity ledger — Reminders example vs iOS 27 stock Reminders

Stock: iPhone 17 simulator (A10F654F, iOS 27.0, 402×874 pt), `com.apple.reminders`.
Ours: iPhone 17e simulator (E297C542, iOS 27.0, 390×844 pt), `Reminders.app` from the `Reminders` scheme.
Evidence pairs live under `Evidence/Parity/<row>/{stock,ours}-*.png`; geometry comes from the Xcode device
hierarchy dumps (points), colors from sRGB pixel samples of the screenshots.

Excluded by the brief: the bottom-bar search field and the "+" New Reminder bar item (placement, style, behaviour).

| Row | Stock evidence | Ours evidence | Differences found → fixed | Status |
|---|---|---|---|---|
| home: tiles | home/stock-home.png | home/ours-home-before.png → home/ours-home.png | Tiles 181×80, 8 pt gaps, radius 18, 16 pt under the bar (ours were 173×84, 12 pt gaps, 49 pt under the bar); stock gradients sampled top→bottom: Today (125,195,239)→(102,185,237), Scheduled (241,157,156)→(238,142,140), All (106,106,106)→(80,80,80), Completed (166,174,179)→(155,163,169); glyphs are bare white (ours had a tinted square behind); Today's glyph is a calendar page with the day number (drawn); title is title3 semibold (ours headline). Flagged gradient not sampled yet (stock had nothing flagged) — estimated. | done (flagged fill pending sample) |
| home: My Lists | home/stock-home.png | home/ours-home.png | Header text resolved secondary (`.primary` inside the header's secondary style) → explicit `Color.primary`; rows 70 pt → 62 pt (vertical padding removed); badge flat color, glyph 16 pt semibold (was gradient, 14 pt bold); badge→title 16 pt, count→chevron 10 pt, chevron body semibold. Add List bar glyph composed (page + plus badge; no SF Symbol). | done |
| home: Tags | — | home/ours-home.png | The simulator's stock Reminders has no Tags UI (hashtags typed via the device tools stay plain text; the Details sheet has no Tags row), so no stock reference exists. Ours restyled to the My Lists row geometry (flat gray badge, 62 pt rows, body chevron). | blocked (no stock reference on the simulator) |
| list detail: title | list-detail/stock-personal.png | list-detail/ours-personal-before.png → list-detail/ours-personal.png | Large blue title 34 pt bold at x 16, first row 106 pt under the safe area: identical after fixing the title row to 52 pt (min row height 42 had shrunk it). | done |
| list detail: rows | list-detail/stock-personal.png | list-detail/ours-personal.png | Stock: no separators, 63 pt rows with a gray line (42 pt title-only), circle centred 29 pt from the edge and 10 pt under the row top, title at x 54, subtitle 24 pt under the title top, `!!! ` in the list color. Ours had separators, 74 pt rows, subtitle 22 pt down, 46 pt title-only rows (the title2 circle glyph was 26 pt tall). Fixed: separators hidden, row insets 10/16, min row height 42, VStack spacing 4, circle frame 26×20. Circle stroke color identical (209,209,214 vs 208,208,209). | done |
| list detail: sort menu | | | | open |
| list detail: show/hide completed | | | | open |
| inline edit card (chips, Return-continues, Done) | inline-edit/stock-card-new.png | inline-edit/ours-card-new-before.png | Card 107 pt (ours 120 → 112), circle centred 29 pt (ours 31 → 29), chips at x 54 (ours 56 → 54), (i) 26 pt from the trailing edge (ours 28 → 26). Date chip menu items now carry the stock `N.calendar` day glyphs (SF Symbols 7). Stock reverses the menu's item order when it opens upward (Custom at the top, None at the bottom); SwiftUI `Menu` keeps declaration order — recorded, not fixable in SwiftUI. Return-continues and Done were already verified 2026-09-15 morning. | done (menu order: blocked, SwiftUI Menu does not flip for upward presentation) |
| Details sheet | details-sheet/stock-details-top.png, -full.png, -date-on.png | details-sheet/ours-details-before.png → ours-details.png | Stock: opens at content height (624 of 874 pt) and grows to full on a drag, no grabber, opaque grouped background, dimmed behind; sections Date & Time / Organisation (List card, then Priority card) / Places & People (Location); List row shows the badge once and the list name as the value; the card sits 22 pt under the bar. Ours had a large-only sheet, one Organisation card holding Priority/Tags/Flag/Location, a badge repeated in the List value, and a 49 pt gap. Fixed all of these (Tags and Flag kept as one card after Priority — the simulator's stock has no such rows). Remaining: SwiftUI presents a partial detent as the iOS 26 floating inset sheet (0.96 scale, side margins) while stock is edge-attached. | done (partial-detent inset: blocked, no SwiftUI API for an edge-attached partial sheet) |
| New Reminder sheet | new-reminder-sheet/stock-new.png | new-reminder-sheet/ours-new-before.png → ours-new.png | Structure already matched (title/notes card, Date & Time, More Options: List + Details, disabled Done, X). Missing the quick bar above the keyboard (Date & Time menu, Location menu, Flag, Photos disabled): added as a `safeAreaBar` shown while a field has the keyboard — a `.keyboard` toolbar placement never appeared inside this sheet. | done |
| List Info / New List sheet | | | | open |
| tag picker | | | | open |
| search results (field excluded) | | | | open |
| swipe actions | | | | open |
| Edit-mode reorder | | | | open |
| completion circle + grace | | | | open |
| row insert/delete/move animations | | | | open |
| sheet present/dismiss | | | | open |
| push/pop | | | | open |
| empty states | | | | open |
| Dynamic Type ×2 | | | | open |
| dark mode | | | | open |

## Log

- 2026-09-15 22:38 baseline: `reminders.xcworkspace` scheme 67/67 green on main d325289. Stock app launched on the iPhone 17; a "You won't be notified" card was dismissed before capture.
- 2026-09-15 22:47 home tiles + My Lists restyled; `listSectionMargins(.top, 0)` closes the gap under the bar.
- 2026-09-15 22:50 stock content added on the iPhone 17 (Personal: Pay rent !!! Today, Dentist appointment, Book flights to Lisbon Tomorrow) for the list-detail, card, and Details comparisons.
- 2026-09-15 23:06 functional defect found while re-launching ours onto an open list: the detail stayed empty (filter restored from a mount task after the detail's first read). Fixed by restoring the session synchronously in `onMount`; new test `a relaunch onto an open list reads its rows` — 68/68.
- 2026-09-15 23:14 Details sheet regrouped + partial detent; New Reminder quick bar; list rows/card geometry. 68/68 (run by the principal in the GUI).
- Tooling: `DeviceInteractionSynthesize` screenshots are 1× — evidence is captured with `simctl io screenshot` (3×). Only one device-interaction session exists at a time (starting a second ends the first; `RunProject` also ends it), and session names cannot be reused.
