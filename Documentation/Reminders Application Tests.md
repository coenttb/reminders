# Reminders Application Tests

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## Tests/Reminders Application Tests/Reminder Application Tests.swift

- `pending.toggle(a)` — A second tap on a pending reminder reverts it; the period ending empties the set.
- `#expect(!Reminder.Search(text: "#so").matchesReminders)` — Typing a tag prefix alone names no reminders; with a token it does, on the tokens alone.
- `let listIDs = Set(a.lists.map(\.id)), tagIDs = Set(a.tags.map(\.id))` — Every reminder belongs to one of the lists, every tag it carries is in the set, and identifiers are distinct; positions follow the manual order.
