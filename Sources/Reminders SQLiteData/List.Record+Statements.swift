public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension List<Reminder>.Record {
    /// Puts a list at the end of the user's order.
    public static func placeLast(_ id: List<Reminder>.ID) -> UpdateOf<List<Reminder>.Record> {
        List<Reminder>.Record.find(id).update { $0.position = List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    /// The columns an edit changed, and nothing else; nil when no column differs.
    public static func changes(from original: List<Reminder>, to draft: List<Reminder>) -> UpdateOf<List<Reminder>.Record>? {
        guard draft != original else { return nil }
        return List<Reminder>.Record.find(original.id).update { row in
            if draft.title != original.title { row.title = draft.title }
            if draft.color != original.color { row.color = Color.Hex(draft.color) }
            if draft.position != original.position { row.position = draft.position }
        }
    }

    /// Removes the list; its reminders go with it by the foreign key. When it was the last one,
    /// the default list takes its place under the given identifier.
    public static func delete(_ id: List<Reminder>.ID, replacement: List<Reminder>.ID, in db: Database) throws {
        try List<Reminder>.Record.find(id).delete().execute(db)
        if try List<Reminder>.Record.all.fetchCount(db) == 0 {
            try List<Reminder>.Record.insert { List<Reminder>.Record(.default(id: replacement)) }.execute(db)
        }
    }

    /// Reorders the lists as the user dragged them: each takes the position of its place in the order.
    public static func reorder(_ ids: [List<Reminder>.ID]) -> UpdateOf<List<Reminder>.Record> {
        List<Reminder>.Record.where { $0.id.in(ids) }.update { row in
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
