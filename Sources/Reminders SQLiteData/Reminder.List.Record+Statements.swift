public import Reminders
public import SQLiteData
public import Tagged

extension Reminder.List.Record {
    /// Puts a list at the end of the user's order.
    public static func placeLast(_ id: Reminder.List.ID) -> UpdateOf<Reminder.List.Record> {
        Reminder.List.Record.find(id).update { $0.position = Reminder.List.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    /// The columns an edit changed, and nothing else; nil when no column differs.
    public static func changes(from original: Reminder.List, to draft: Reminder.List) -> UpdateOf<Reminder.List.Record>? {
        guard draft != original else { return nil }
        return Reminder.List.Record.find(original.id).update { row in
            if draft.title != original.title { row.title = draft.title }
            if draft.color != original.color { row.color = draft.color.hex }
            if draft.position != original.position { row.position = draft.position }
        }
    }

    /// Removes the list; its reminders go with it by the foreign key. When it was the last one,
    /// the default list takes its place under the given identifier.
    public static func delete(_ id: Reminder.List.ID, replacement: Reminder.List.ID, in db: Database) throws {
        try Reminder.List.Record.find(id).delete().execute(db)
        if try Reminder.List.Record.all.fetchCount(db) == 0 {
            try Reminder.List.Record.insert { Reminder.List.Record(.default(id: replacement)) }.execute(db)
        }
    }

    /// Reorders the lists as the user dragged them: each takes the position of its place in the order.
    public static func reorder(_ ids: [Reminder.List.ID]) -> UpdateOf<Reminder.List.Record> {
        Reminder.List.Record.where { $0.id.in(ids) }.update { row in
            let places = Array(ids.enumerated())
            guard let first = places.first else { return }
            row.position = places.dropFirst()
                .reduce(Case(row.id).when(first.element, then: first.offset)) { cases, place in
                    cases.when(place.element, then: place.offset)
                }
                .else(row.position)
        }
    }
}
