# Canonical view simulator evidence

Captured by the passing `RemindersUITests.testDomainFirstViewsEndToEnd` run on
September 20, 2026: iPhone 17, iOS 27.0 (24A434), arm64. The task-owned simulator is
`1EC882FE-7067-44C2-B068-F52B6790A536`. These are unmodified XCTest screenshots;
matching `-hierarchy.txt` files preserve the accessibility observations.

| Stage | Screenshot |
| --- | --- |
| Initial root | [Root](01-root.png) |
| New draft with keyboard focus | [New draft](02-new-draft.png) |
| Completion applied | [Completed](03-completed.png) |
| Editing saved with Return | [Edited](04-edited.png) |
| Exactly one editor after switching rows | [Switched editor](04b-switched-editor.png) |
| Saved title and completion after relaunch | [Persisted](05-persisted.png) |
| Reminder deleted | [Deleted reminder](06-deleted-reminder.png) |
| Validation list deleted; original sample retained | [Cleaned up](07-cleaned-up.png) |

Result bundle: `Test-Reminders UI Tests-2026.09.20_00-36-13-+0200.xcresult` under
`/tmp/institute-reminders-derived/Logs/Test`. One UI test passed with no failures,
skips or recorded runtime warnings. See [the design and audit](../../SWIFTUI-SYNTAX.md)
for workspace commands and the distinction from prior user iPhone validation.
