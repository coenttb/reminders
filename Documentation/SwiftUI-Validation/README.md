# Canonical view simulator evidence

Archived from simulator validation on September 20, 2026: iPhone 17,
iOS 27.0 (24A434), arm64. These unmodified screenshots and matching
`-hierarchy.txt` files preserve observations from that checkpoint. The former
UI automation target has been removed; current automated tests use Swift Testing.

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

See [the design and audit](../../SWIFTUI-SYNTAX.md) for current workspace commands.
