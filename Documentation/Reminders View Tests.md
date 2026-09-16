# Reminders View Tests

The notes that stood as comments in the target's source, kept here by file and by the declaration or statement they describe. The source itself carries no comments; RESEARCH.md holds the rulings and their history.


## reminders-apple/Tests/Reminders View Tests/Reminder.View Tests.swift

- `let now = Date(timeIntervalSince1970: 1_234_567_890)` — 23:31 UTC on the 13th is 08:31 on the 14th in Tokyo; a reminder due 01:00 UTC on the 14th is today there, tomorrow in UTC.
- `#expect(worded(.day(in6)) == in6.formatted(style.weekday(.wide)))` — The week runs to six days out; the seventh is a date, and only one day back is Yesterday.
- `let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)` — The row's subtitle follows the calendar it is given: the same instant is another day elsewhere.
