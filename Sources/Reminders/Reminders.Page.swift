public import Reminder
public import Tagged

extension Reminders {
    // One screen's rows in the sections the screen shows them in; `rows` stays the flat, ordered whole.
    public struct Page: Hashable, Sendable {
        public var sections: [Section]
        public var total: Int
        public var completed: Int
        public var highlights: [Reminder.ID: Reminders.Highlight]

        public init(sections: [Section], total: Int = 0, completed: Int = 0, highlights: [Reminder.ID: Reminders.Highlight] = [:]) {
            self.sections = sections
            self.total = total
            self.completed = completed
            self.highlights = highlights
        }

        public init(rows: [Reminder] = [], total: Int = 0, completed: Int = 0, highlights: [Reminder.ID: Reminders.Highlight] = [:]) {
            self.init(sections: rows.isEmpty ? [] : [Section(key: .rows, rows: rows)], total: total, completed: completed, highlights: highlights)
        }

        public var rows: [Reminder] { sections.flatMap(\.rows) }
    }
}

extension Reminders.Page {
    public struct Section: Identifiable, Hashable, Sendable {
        public var key: Reminders.Section
        public var rows: [Reminder]

        public var id: Reminders.Section { key }

        public init(key: Reminders.Section, rows: [Reminder] = []) {
            self.key = key
            self.rows = rows
        }
    }

    // The rows in the order read, folded into the screen's sections: the listed ones first even when empty,
    // the ones a row brings (an overdue day, a month) slotted in by date. One pass over the rows.
    public init<Rows: Sequence>(folding rows: Rows, into listed: [Reminders.Section], by key: (Reminder) -> Reminders.Section, total: Int, completed: Int) where Rows.Element == Reminder {
        var sections = listed.map { Section(key: $0) }
        var indices = Dictionary(uniqueKeysWithValues: sections.enumerated().map { ($1.key, $0) })
        for row in rows {
            let key = key(row)
            if let index = indices[key] {
                sections[index].rows.append(row)
            } else {
                let index = sections.firstIndex { key < $0.key } ?? sections.endIndex
                sections.insert(Section(key: key, rows: [row]), at: index)
                indices = Dictionary(uniqueKeysWithValues: sections.enumerated().map { ($1.key, $0) })
            }
        }
        self.init(sections: sections, total: total, completed: completed)
    }

    public mutating func insert(_ reminder: Reminder, after anchor: Reminder.ID) -> Bool {
        for index in sections.indices {
            if let at = sections[index].rows.firstIndex(where: { $0.id == anchor }) {
                sections[index].rows.insert(reminder, at: at + 1)
                return true
            }
        }
        return false
    }

    // A row moves to the end of its section while it is the new card, as the stock card sits under the completed rows.
    public mutating func moveToEnd(_ id: Reminder.ID) {
        for index in sections.indices {
            if let at = sections[index].rows.firstIndex(where: { $0.id == id }) {
                sections[index].rows.append(sections[index].rows.remove(at: at))
                return
            }
        }
    }

    public mutating func removeAll(where shouldRemove: (Reminder) -> Bool) {
        for index in sections.indices { sections[index].rows.removeAll(where: shouldRemove) }
    }
}
